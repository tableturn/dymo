defmodule Dymo.TaggerImpl do
  @moduledoc """
  This tagger helps with tagging objects using an ecto-backed repo.
  """

  use Ecto.Schema
  import Ecto.{Changeset, Query}

  alias Ecto.{Query, Schema}
  alias Ecto.Association.NotLoaded
  alias Dymo.{Tag, Tag.Ns, Taggable, Tagger}

  @behaviour Tagger

  @type join_table :: Tagger.join_table()
  @type join_key :: Tagger.join_key()

  @doc """
  Adds labels to a given instance of a model.

  ## Examples

      iex> %Dymo.Post{title: "Hey"}
      ...>  |> Dymo.repo().insert!
      ...>  |> TaggerImpl.set_labels([{:number, "three"}, {:number, "four"}])
      ...>  |> TaggerImpl.add_labels({:number, "five"})
      ...>  |> Map.get(:tags)
      ...>  |> Enum.map(& &1.label)
      ...>  |> Enum.sort()
      ~w(five four three)
  """
  @impl Tagger
  @spec add_labels(Taggable.t(), Tag.label_or_labels(), keyword) :: Schema.t()
  def add_labels(struct, lbls, opts \\ [])

  def add_labels(%{tags: %NotLoaded{}} = struct, lbls, opts),
    do:
      struct
      |> Dymo.repo().preload(:tags)
      |> add_labels(lbls, opts)

  def add_labels(%{id: _, tags: tags} = struct, lbls, opts) do
    # Prepare a lookup table of the existing tags. For this, we make
    # a map such as %{{ns, label} => true}
    existing_tags =
      tags
      |> Enum.reduce(%{}, fn lbl, acc ->
        acc |> Map.put(Tag.tuppleify(lbl), true)
      end)

    lbls
    # Make the labels a list if not one.
    |> List.wrap()
    # Transform every label into a {ns, label} tupple.
    |> Enum.map(&Tag.tuppleify/1)
    # Remove the ones that are already present.
    |> Enum.reject(&Map.get(existing_tags, &1))
    # Add the existing ones.
    |> Enum.concat(tags)
    # Commit.
    |> maintain_labels_tags(struct, opts)
  end

  @doc """
  Sets the labels associated with an instance of a model, for the
  given namespace.

  If any other labels are associated to the given model and namespace,
  they are discarded if they are not part of the list of passed new
  labels.

  ## Examples

      iex> post = %Dymo.Post{title: "Hey"}
      iex> %{tags: tags} = post
      ...>  |> Dymo.repo().insert!
      ...>  |> TaggerImpl.set_labels([{:rank, "one"}, {:rank, "two"}])
      iex> Enum.map(tags, & &1.label)
      ["one", "two"]
  """
  @impl Tagger
  @spec set_labels(Taggable.t(), Tag.label_or_labels(), keyword) :: Schema.t()
  def set_labels(struct, lbls, opts \\ [])

  def set_labels(%{tags: %NotLoaded{}} = struct, lbls, opts),
    do:
      struct
      |> Dymo.repo().preload(:tags)
      |> set_labels(lbls, opts)

  def set_labels(%{id: _, tags: tags} = struct, lbls, opts),
    do:
      lbls
      # Make the labels a list if not one.
      |> List.wrap()
      # Transform each label into a {ns, label} tupple.
      |> Enum.map(&Tag.tuppleify/1)
      # Create a map of ns => [label].
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
      # Replace tags with new one by overwritting existing namespaces.
      |> Enum.reduce(group_by_ns(tags), fn {ns, labels}, acc ->
        acc |> Map.put(ns, labels)
      end)
      # From a map get back into an array.
      |> flatten()
      # Commit.
      |> maintain_labels_tags(struct, opts)

  @doc """
  Removes labels from a given instance of a model.

  ## Examples

      iex> %{tags: tags} = %Dymo.Post{title: "Hey"}
      ...>  |> Dymo.repo().insert!
      ...>  |> TaggerImpl.set_labels([{:number, "six"}, {:number, "seven"}])
      ...>  |> TaggerImpl.remove_labels({:number, "six"})
      iex> Enum.map(tags, & &1.label)
      ["seven"]
  """
  @impl Tagger
  @spec remove_labels(Taggable.t(), Tag.string_or_strings(), keyword) :: Schema.t()
  def remove_labels(struct, lbls, opts \\ [])

  def remove_labels(%{tags: %NotLoaded{}} = struct, lbls, opts),
    do:
      struct
      |> Dymo.repo().preload(:tags)
      |> remove_labels(lbls, opts)

  def remove_labels(%{id: _, tags: tags} = struct, lbls, _opts),
    do:
      lbls
      # Make the labels a list if not one.
      |> List.wrap()
      # Transform every label into a {ns, label} tupple.
      |> Enum.map(&Tag.tuppleify/1)
      # Create a map of ns => [label].
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
      # Remove from existing tags.
      |> Enum.reduce(group_by_ns(tags), fn {ns, labels}, acc ->
        acc |> Map.update(ns, [], &(&1 -- labels))
      end)
      # Transform back into an array.
      |> flatten
      # Commit.
      |> maintain_labels_tags(struct)

  @doc """
  Generates query for retrieving labels associated with a schema's
  instance.
  """
  @impl Tagger
  @spec labels(Taggable.t(), join_table, join_key, keyword) :: Query.t()
  def labels(%{__struct__: schema, tags: _} = struct, jt, jk, opts \\ [])
      when is_binary(jt) and is_atom(jk) do
    {:ok, cast_ns} =
      opts
      |> Keyword.get(:ns, nil)
      |> Ns.cast()

    Tag
    |> join_tagging(pkey_type(schema), struct, jt, jk)
    |> where([t], t.ns == ^cast_ns)
    |> distinct([t, tg], t.label)
    |> select([t, tg], t.label)
  end

  @doc """
  Generates query for retrieving labels associated with a schema.

  ## Examples

      iex> %Dymo.Post{title: "Hey"}
      ...>  |> Dymo.repo().insert!
      ...>  |> TaggerImpl.set_labels([{:number, "eight"}, {:number, "nine"}])
      iex> "taggings"
      ...>  |> TaggerImpl.all_labels(:post_id, ns: :number)
      ...>  |> Dymo.repo().all()
      ["eight", "nine"]
  """
  @impl Tagger
  @spec all_labels(join_table, join_key, keyword) :: Query.t()
  def all_labels(jt, jk, opts \\ [])
      when is_binary(jt) and is_atom(jk) do
    {:ok, cast_ns} =
      opts
      |> Keyword.get(:ns, nil)
      |> Ns.cast()

    Tag
    |> join(:left, [t], tg in ^jt, on: t.id == tg.tag_id)
    |> distinct([t, tg], tg.tag_id)
    |> where([t, tg], t.ns == ^cast_ns and not is_nil(field(tg, ^jk)))
    |> order_by([t, tg], asc: t.label)
    |> select([t, tg], t.label)
  end

  @doc """
  Queries models that are tagged with the given labels.

  ## Examples

      iex> %{id: id} = %Dymo.Post{title: "Hey"}
      ...>  |> Dymo.repo().insert!
      ...>  |> TaggerImpl.set_labels([{:number, "ten"}, {:number, "eleven"}])
      iex> id == Dymo.Post
      ...>  |> TaggerImpl.labeled_with({:number, "ten"}, "taggings", :post_id)
      ...>  |> Dymo.repo().all()
      ...>  |> hd
      ...>  |> Map.get(:id)
      true
      iex> Dymo.Post
      ...>  |> TaggerImpl.labeled_with({:unknown, "nothing"}, "taggings", :post_id)
      ...>  |> Dymo.repo().all()
      []
  """
  @impl Tagger
  @spec labeled_with(module, Tag.label_or_labels(), join_table(), join_key()) ::
          Query.t()
  def labeled_with(module, label_or_labels, jt, jk)
      when is_binary(jt) and is_atom(jk) do
    {nss, lbls} =
      label_or_labels
      |> List.wrap()
      |> Enum.map(&Tag.cast/1)
      |> Enum.reduce({[], []}, fn
        tag, {nss, lbls} -> {[tag.ns | nss], [tag.label | lbls]}
      end)

    # TODO: This query is most likelly wrong - because it requires
    # "label in a list and namespace in a list" and it mixes things.
    # The right way to do this would be to accumulate a where fragment in
    # a loop.
    module
    |> join(:inner, [m], tg in ^jt, on: m.id == field(tg, ^jk))
    |> join(:inner, [m, tg], t in Tag, on: t.id == tg.tag_id)
    |> where([m, tg, t], t.ns in ^nss and t.label in ^lbls)
    |> group_by([m, tg, t], m.id)
    |> having([m, tg, t], count(field(tg, ^jk)) == ^length(lbls))
    |> order_by([m, tg, t], asc: m.inserted_at)
  end

  @spec maintain_labels_tags([Tag.t()], Taggable.t(), keyword) :: Schema.t()
  defp maintain_labels_tags(tags, struct, opts \\ []) do
    # Based on options, we might want to skip creation of non-existent tags.
    method =
      opts
      |> Keyword.get(:create_missing, true)
      |> if do
        &Tag.find_or_create!/1
      else
        &Tag.find_existing/1
      end

    # Find the specified tags (create them if options allow that).
    safe_tags =
      tags
      |> method.()
      |> Enum.filter(&(&1 != nil))

    # Update assocs.
    struct
    |> change
    |> put_assoc(:tags, safe_tags)
    |> Dymo.repo().update!()
  end

  defp group_by_ns(tags) when is_list(tags),
    do: tags |> Enum.group_by(& &1.ns, & &1.label)

  defp flatten(tags) when is_map(tags),
    do:
      tags
      |> Enum.reduce([], fn {ns, lbls}, acc ->
        lbls
        |> Enum.map(&Tag.cast({ns, &1}))
        |> Enum.concat(acc)
      end)

  defp join_tagging(q, [:id], %{id: id}, jt, jk),
    do: join(q, :inner, [t], tg in ^jt, on: t.id == tg.tag_id and field(tg, ^jk) == ^id)

  defp join_tagging(q, [:binary_id], %{id: id}, jt, jk),
    do:
      join(q, :inner, [t], tg in ^jt,
        on: t.id == tg.tag_id and field(tg, ^jk) == type(^id, :binary_id)
      )

  defp join_tagging(_, _, _, _, _),
    do: raise("#{__MODULE__} only supports `[:id]` and `[:binary_id]` primary key types.")

  defp pkey_type(schema),
    do:
      :primary_key
      |> schema.__schema__()
      |> Enum.map(&schema.__schema__(:type, &1))
end
