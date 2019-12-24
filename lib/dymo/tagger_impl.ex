defmodule Dymo.TaggerImpl do
  @moduledoc """
  This tagger helps with tagging objects using a backed ecto repo.
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

      iex> labels = ~w(three four)
      iex> %{tags: tags} = %Dymo.Post{title: "Hey"}
      ...>  |> Dymo.repo().insert!
      ...>  |> TaggerImpl.set_labels(:number, labels)
      ...>  |> TaggerImpl.add_labels(:number, "five")
      iex> Enum.map(tags, & &1.label)
      ["three", "four", "five"]
  """
  @spec add_labels(Taggable.t(), Tag.ns(), Tag.string_or_strings(), keyword) :: Schema.t()
  def add_labels(struct, ns, lbls, opts \\ [])

  def add_labels(%{tags: %NotLoaded{}} = struct, ns, lbls, opts),
    do:
      struct
      |> Dymo.repo().preload(:tags)
      |> add_labels(ns, lbls, opts)

  def add_labels(%{id: _, tags: tags} = struct, ns, lbls, opts) do
    cast_ns = Ns.cast!(ns)
    existing_tags = tags |> Enum.reduce(%{}, &Map.put(&2, {&1.ns, &1.label}, true))

    lbls
    |> List.wrap()
    |> Enum.map(&{cast_ns, &1})
    |> Enum.reject(&Map.get(existing_tags, &1))
    |> Enum.concat(tags)
    |> maintain_labels_tags(struct, opts)
  end

  @doc """
  Sets the labels associated with an instance of a model, for the
  given namespace.

  If any other labels are associated to the given model and namespace,
  they are discarded if they are not part of the list of passed new
  labels.

  ## Examples

      iex> labels = ~w(one two)
      iex> post = %Dymo.Post{title: "Hey"}
      iex> %{tags: tags} =
      ...>  post
      ...>  |> Dymo.repo().insert!
      ...>  |> TaggerImpl.set_labels(:rank, labels)
      iex> Enum.map(tags, & &1.label)
      ["one", "two"]
  """
  @spec set_labels(Taggable.t(), Tag.ns(), Tag.string_or_strings(), keyword) :: Schema.t()
  def set_labels(struct, ns, lbls, opts \\ [])

  def set_labels(%{tags: %NotLoaded{}} = struct, ns, lbls, opts),
    do:
      struct
      |> Dymo.repo().preload(:tags)
      |> set_labels(ns, lbls, opts)

  def set_labels(%{id: _, tags: tags} = struct, ns, lbls, opts) do
    tags
    |> group_by_ns()
    |> Map.put(Ns.cast!(ns), List.wrap(lbls))
    |> flatten()
    |> maintain_labels_tags(struct, opts)
  end

  @doc """
  Removes labels from a given instance of a model.

  ## Examples

      iex> labels = ~w(six seven)
      iex> %{tags: tags} = %Dymo.Post{title: "Hey"}
      ...>  |> Dymo.repo().insert!
      ...>  |> TaggerImpl.set_labels(:number, labels)
      ...>  |> TaggerImpl.remove_labels(:number, "six")
      iex> Enum.map(tags, & &1.label)
      ["seven"]
  """
  @spec remove_labels(Taggable.t(), Tag.ns(), Tag.string_or_strings()) :: Schema.t()
  def remove_labels(%{tags: %NotLoaded{}} = struct, ns, lbls),
    do:
      struct
      |> Dymo.repo().preload(:tags)
      |> remove_labels(ns, lbls)

  def remove_labels(%{id: _, tags: tags} = struct, ns, lbls),
    do:
      tags
      |> group_by_ns()
      |> Map.update(Ns.cast!(ns), [], &(&1 -- List.wrap(lbls)))
      |> flatten()
      |> maintain_labels_tags(struct)

  @doc """
  Generates query for retrieving labels associated with a schema.

  ## Examples

      iex> labels = ~w(eight nine)
      iex> post = %Dymo.Post{title: "Hey"}
      ...>  |> Dymo.repo().insert!
      ...>  |> TaggerImpl.set_labels(:number, labels)
      iex> "taggings"
      ...>  |> TaggerImpl.query_all_labels(:post_id, :number)
      ...>  |> Dymo.repo().all()
      ["eight", "nine"]
  """
  @spec query_all_labels(join_table, join_key, Tag.ns()) :: Query.t()
  def query_all_labels(jt, jk, ns) when is_binary(jt) and is_atom(jk),
    do:
      Tag
      |> join(:left, [t], tg in ^jt, on: t.id == tg.tag_id)
      |> distinct([t, tg], tg.tag_id)
      |> where([t, tg], t.ns == ^Ns.cast!(ns) and not is_nil(field(tg, ^jk)))
      |> order_by([t, tg], asc: t.label)
      |> select([t, tg], t.label)

  @doc """
  Generates query for retrieving labels associated with a schema's
  instance.
  """
  @spec query_labels(Taggable.t(), join_table, join_key, Tag.ns()) :: Query.t()
  def query_labels(%{__struct__: schema, tags: _} = struct, jt, jk, ns),
    do:
      Tag
      |> join_tagging(pkey_type(schema), struct, jt, jk)
      |> where([t], t.ns == ^Ns.cast!(ns))
      |> distinct([t, tg], t.label)
      |> select([t, tg], t.label)

  @doc """
  Queries models that are tagged with the given labels.

  ## Examples

      iex> labels = ~w(ten eleven)
      iex> %{id: id} = %Dymo.Post{title: "Hey"}
      ...>  |> Dymo.repo().insert!
      ...>  |> TaggerImpl.set_labels(:number, labels)
      iex> id == Dymo.Post
      ...>  |> TaggerImpl.query_labeled_with({:number, "ten"}, "taggings", :post_id)
      ...>  |> Dymo.repo().all()
      ...>  |> hd
      ...>  |> Map.get(:id)
      true
      iex> Dymo.Post
      ...>  |> TaggerImpl.query_labeled_with({:unknown, "nothing"}, "taggings", :post_id)
      ...>  |> Dymo.repo().all()
      []
  """
  @spec query_labeled_with(module, Tag.label_or_labels(), join_table(), join_key()) :: Query.t()
  def query_labeled_with(module, label_or_labels, jt, jk) when is_binary(jt) and is_atom(jk) do
    {nss, lbls} =
      label_or_labels
      |> List.wrap()
      |> Enum.map(&Tag.cast/1)
      |> Enum.reduce({[], []}, fn tag, {nss, lbls} -> {[tag.ns | nss], [tag.label | lbls]} end)

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

  @spec labels(Taggable.t(), Tag.ns()) :: [Tag.label()]
  def labels(%{id: _, tags: _} = struct, ns) do
    ns = Ns.cast!(ns)

    struct
    |> Dymo.repo().preload(:tags)
    |> Map.get(:tags)
    |> Enum.filter(&(&1.ns == ns))
    |> Enum.map(& &1.label)
  end

  @spec maintain_labels_tags([Tag.t()], Taggable.t(), keyword) :: Schema.t()
  defp maintain_labels_tags(tags, struct, opts \\ []) do
    method =
      opts
      |> Keyword.get(:create_missing, true)
      |> if do
        &Tag.find_or_create!/1
      else
        &Tag.find_existing/1
      end

    concrete_tags =
      tags
      |> method.()
      |> Enum.filter(&(&1 != nil))

    struct
    |> change
    |> put_assoc(:tags, concrete_tags)
    |> Dymo.repo().update!()
  end

  defp group_by_ns(tags) when is_list(tags),
    do: Enum.group_by(tags, & &1.ns, & &1.label)

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
