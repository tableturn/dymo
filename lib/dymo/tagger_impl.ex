defmodule Dymo.TaggerImpl do
  @moduledoc """
  This tagger helps with tagging objects using an ecto-backed repo.
  """

  use Ecto.Schema
  import Ecto.{Changeset, Query}

  alias Ecto.{Query, Schema}
  alias Dymo.{Tag, Tag.Ns, Taggable, Tagger}

  @behaviour Tagger

  @type join_table :: Tagger.join_table()
  @type join_key :: Tagger.join_key()

  # TODO: Add tests when no namespace is passed.
  @impl Tagger
  @spec tags(Taggable.t(), join_table, join_key, keyword) :: Query.t()
  def tags(%{__struct__: schema, tags: _} = struct, jt, jk, opts \\ [])
      when is_binary(jt) and is_atom(jk) do
    base =
      from(t in Tag, as: :tags)
      |> join_taggings(pkey_type(schema), struct, jt, jk)
      |> distinct([tags: t, taggings: tg], t.label)
      |> order_by([tags: t], asc: [t.ns, t.label])

    opts
    |> Keyword.get(:ns)
    |> case do
      nil -> base
      ns -> base |> where([tags: t], t.ns == ^Ns.cast!(ns))
    end
  end

  @doc """
  Generates query for retrieving labels associated with a schema's
  instance.
  """
  @impl Tagger
  @spec labels(Taggable.t(), join_table, join_key, keyword) :: Query.t()
  def labels(%{__struct__: _, tags: _} = struct, jt, jk, opts \\ [])
      when is_binary(jt) and is_atom(jk),
      do:
        struct
        |> tags(jt, jk, opts)
        |> select([tags: t, taggings: tg], t.label)

  @doc """
  Sets the labels associated with an instance of a model, for the
  given namespace.

  If any other labels are associated to the given model and namespace,
  they are discarded if they are not part of the list of passed new
  labels.

  Note that only tags with the `:assignable` boolean set to `true` can be
  set. If a tag which `:assignable` flag is false is provided, it won't be
  assigned to the target object **but no error will be returned**.

  ## Examples

      iex> post =
      ...>   %Dymo.Post{title: "Hey"}
      ...>     |> Dymo.repo().insert!
      iex> %{ns: :special, label: "nope", assignable: false}
      ...>   |> Dymo.Tag.create_changeset()
      ...>   |> Dymo.repo().insert!
      iex> post
      ...>   |> TaggerImpl.set_labels([{:rank, "one"}, {:rank, "two"}, {:special, "nope"}], create_missing: true)
      ...>   |> Map.get(:tags)
      ...>   |> Enum.map(& {&1.ns, &1.label})
      [{:rank, "one"}, {:rank, "two"}]
      iex> post
      ...>   |> TaggerImpl.set_labels({:rank, "officer"}, create_missing: true)
      ...>   |> Map.get(:tags)
      ...>   |> Enum.map(& {&1.ns, &1.label})
      [{:rank, "officer"}]
  """
  @impl Tagger
  @spec set_labels(Taggable.t(), Tag.label_or_labels(), keyword) :: Schema.t()
  def set_labels(struct, label_or_labels, opts \\ []) do
    %{tags: tags} = full_struct = struct |> Dymo.repo().preload(:tags)
    default_ns = opts |> Keyword.get(:ns) |> Ns.cast!()

    label_or_labels
    # Make the labels a list if not one.
    |> List.wrap()
    # Transform each label into a {ns, label} tupple.
    |> tuppleify(default_ns)
    # Create a map of ns => [label].
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    # Replace tags with new one by overwritting existing namespaces.
    |> Enum.reduce(group_labels_by_namespace(tags), fn {ns, labels}, acc ->
      acc |> Map.put(ns, labels)
    end)
    # From a map get back into an array.
    |> groupped_labels_to_list()
    # Commit.
    |> maintain_labels_tags(full_struct, opts)
  end

  @doc """
  Adds labels to a given instance of a model.

  ## Examples

      iex> %Dymo.Post{title: "Hey"}
      ...>   |> Dymo.repo().insert!
      ...>   |> TaggerImpl.set_labels([{:number, "three"}, {:number, "four"}], create_missing: true)
      ...>   |> TaggerImpl.add_labels({:number, "five"}, create_missing: true)
      ...>   |> Map.get(:tags)
      ...>   |> Enum.map(& &1.label)
      ...>   |> Enum.sort()
      ~w(five four three)
  """
  @impl Tagger
  @spec add_labels(Taggable.t(), Tag.label_or_labels(), keyword) :: Schema.t()
  def add_labels(struct, lbls, opts \\ []) do
    %{tags: tags} = full_struct = struct |> Dymo.repo().preload(:tags)
    # Get the optional namespace, or default it.
    default_ns = opts |> Keyword.get(:ns) |> Ns.cast!()
    # Prepare a lookup table of the existing tags. For this, we make
    # a map such as %{{ns, label} => true}
    existing_tags =
      tags
      |> Enum.reduce(%{}, fn lbl, acc ->
        acc |> Map.put(tuppleify(lbl, default_ns), true)
      end)

    lbls
    # Make the labels a list if not one.
    |> List.wrap()
    # Transform every label into a {ns, label} tupple.
    |> tuppleify(default_ns)
    # Remove the ones that are already present.
    |> Enum.reject(&Map.get(existing_tags, &1))
    # Add the existing ones.
    |> Enum.concat(tags)
    # Commit.
    |> maintain_labels_tags(full_struct, opts)
  end

  @doc """
  Removes labels from a given instance of a model.

  ## Examples

      iex> %{tags: tags} = %Dymo.Post{title: "Hey"}
      ...>   |> Dymo.repo().insert!
      ...>   |> TaggerImpl.set_labels([{:number, "six"}, {:number, "seven"}], create_missing: true)
      ...>   |> TaggerImpl.remove_labels({:number, "six"})
      iex> Enum.map(tags, & &1.label)
      ["seven"]
  """
  @impl Tagger
  @spec remove_labels(Taggable.t(), Tag.label_or_labels(), keyword) :: Schema.t()
  def remove_labels(struct, lbls, opts \\ []) do
    %{tags: tags} = full_struct = struct |> Dymo.repo().preload(:tags)
    # Get the optional namespace or default it.
    default_ns = opts |> Keyword.get(:ns) |> Ns.cast!()

    lbls
    # Make the labels a list if not one.
    |> List.wrap()
    # Transform every label into a {ns, label} tupple.
    |> tuppleify(default_ns)
    # Create a map of ns => [label].
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    # Remove from existing tags.
    |> Enum.reduce(group_labels_by_namespace(tags), fn {ns, labels}, acc ->
      acc |> Map.update(ns, [], &(&1 -- labels))
    end)
    # Transform back into an array.
    |> groupped_labels_to_list
    # Commit.
    |> maintain_labels_tags(full_struct, opts)
  end

  @doc """
  Generates query for retrieving labels associated with a schema.

  ## Examples

      iex> %Dymo.Post{title: "Hey"}
      ...>   |> Dymo.repo().insert!
      ...>   |> TaggerImpl.set_labels([{:number, "eight"}, {:number, "nine"}], create_missing: true)
      iex> "taggings"
      ...>   |> TaggerImpl.all_labels(:post_id, ns: :number)
      ...>   |> Dymo.repo().all()
      ["eight", "nine"]
  """
  @impl Tagger
  @spec all_labels(join_table, join_key, keyword) :: Query.t()
  def all_labels(jt, jk, opts \\ [])
      when is_binary(jt) and is_atom(jk) do
    cast_ns =
      opts
      |> Keyword.get(:ns)
      |> Ns.cast!()

    from(t in Tag, as: :tags)
    |> join(:left, [tags: t], tg in ^jt, as: :taggings, on: t.id == tg.tag_id)
    |> distinct([tags: t, taggings: tg], tg.tag_id)
    |> where([tags: t, taggings: tg], t.ns == ^cast_ns and not is_nil(field(tg, ^jk)))
    |> select([tags: t, taggings: tg], t.label)
    |> order_by([tags: t], asc: [t.ns, t.label])
  end

  @doc """
  Queries models that are tagged with the given labels.

  ## Examples

      iex> %{id: id} = %Dymo.Post{title: "Hey"}
      ...>   |> Dymo.repo().insert!
      ...>   |> TaggerImpl.set_labels([{:number, "ten"}, {:number, "eleven"}], create_missing: true)
      iex> id == Dymo.Post
      ...>   |> TaggerImpl.labeled_with({:number, "ten"}, "taggings", :post_id)
      ...>   |> Dymo.repo().all()
      ...>   |> hd
      ...>   |> Map.get(:id)
      true
      iex> Dymo.Post
      ...>   |> TaggerImpl.labeled_with({:unknown, "nothing"}, "taggings", :post_id)
      ...>   |> Dymo.repo().all()
      []
  """
  @impl Tagger
  @spec labeled_with(module, Tag.label_or_labels(), join_table(), join_key(), keyword) ::
          Query.t()
  def labeled_with(module, label_or_labels, jt, jk, opts \\ [])
      when is_binary(jt) and is_atom(jk) do
    default_ns =
      opts
      |> Keyword.get(:ns)
      |> Ns.cast!()

    labels =
      label_or_labels
      |> List.wrap()
      |> tuppleify(default_ns)
      |> Enum.uniq()

    opts
    |> Keyword.get(:match_all, false)
    |> if(
      do: module |> labeled_with_all(labels, jt, jk),
      else: module |> labeled_with_any(labels, jt, jk)
    )
  end

  defp labeled_with_any(module, labels, jt, jk) do
    # Get a fragment that ORs all the labels.
    frag =
      labels
      |> Enum.reduce(false, fn {ns, lbl}, acc ->
        dynamic([m, taggings: tg, tags: t], ^acc or (t.ns == ^ns and t.label == ^lbl))
      end)

    module
    |> join(:inner, [m], tg in ^jt, as: :taggings, on: m.id == field(tg, ^jk))
    |> join(:inner, [m, taggings: tg], t in Tag, as: :tags, on: t.id == tg.tag_id)
    |> where(^frag)
    |> distinct([m, tg, t], m.id)
  end

  defp labeled_with_all(module, labels, jt, jk) do
    groupped_labels = labels |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))

    # Get a fragment that ORs all labels.
    frag =
      groupped_labels
      |> Enum.reduce(false, fn {ns, lbls}, acc ->
        dynamic([t], ^acc or (t.ns == ^ns and t.label in ^lbls))
      end)

    # Get all tag IDs matching the specification.
    tag_ids =
      from(t in Tag, as: :tags)
      |> where(^frag)
      |> select([tags: t], t.id)
      |> distinct([tags: t], t.id)
      |> order_by([tags: t], asc: [t.ns, t.label])
      |> Dymo.repo().all

    # Exact match on *all* tag IDs.
    # This query could be optimized to use a subquery instead of the ^tag_ids array.
    module
    |> join(:inner, [m], tg in ^jt, as: :taggings, on: m.id == field(tg, ^jk))
    |> where([m, taggings: tg], tg.tag_id in ^tag_ids)
    |> group_by([m, taggings: tg], m.id)
    |> having([m, taggings: tg], count(field(tg, ^jk)) == ^length(labels))
  end

  @spec tuppleify(Tag.label() | Tag.t() | [Tag.label() | Tag.t()], Ns.t()) ::
          Tag.namespaced_label()
  defp tuppleify(lbls, default_ns) when is_list(lbls),
    do: lbls |> Enum.map(&tuppleify(&1, default_ns))

  defp tuppleify(lbl, default_ns) when is_binary(lbl),
    do: tuppleify({default_ns, lbl}, default_ns)

  defp tuppleify({nil, lbl}, default_ns),
    do: {Ns.cast!(default_ns), lbl}

  defp tuppleify({ns, lbl}, _),
    do: {Ns.cast!(ns), lbl}

  defp tuppleify(%{ns: ns, label: lbl}, default_ns),
    do: tuppleify({ns, lbl}, default_ns)

  @spec maintain_labels_tags(list(Tag.t()), Taggable.t(), keyword) :: Schema.t()
  defp maintain_labels_tags(tags, struct, opts) do
    # Based on options, we might want to skip creation of non-existent tags.
    finder_or_creator =
      opts
      |> Keyword.get(:create_missing, Dymo.create_missing_tags_by_default())
      |> if(do: &Tag.find_or_create!/1, else: &Tag.find_existing/1)

    # Find the specified tags (create them if options allow that).
    safe_tags =
      tags
      |> finder_or_creator.()
      |> Enum.filter(&(&1 != nil))
      |> Enum.filter(& &1.assignable)

    # Update assocs.
    struct
    |> change
    |> put_assoc(:tags, safe_tags)
    |> Dymo.repo().update!()
  end

  defp group_labels_by_namespace(tags) when is_list(tags),
    do: tags |> Enum.group_by(& &1.ns, & &1.label)

  defp groupped_labels_to_list(tags) when is_map(tags),
    do:
      tags
      |> Enum.reduce([], fn {ns, lbls}, acc ->
        lbls
        |> Enum.map(&Tag.to_struct({ns, &1}))
        |> Enum.concat(acc)
      end)

  defp join_taggings(q, [pk_type], %{id: id}, jt, jk) when pk_type in ~w(id binary_id)a,
    do:
      q
      |> join(:inner, [tags: t], tg in ^jt,
        as: :taggings,
        on: t.assignable and t.id == tg.tag_id and field(tg, ^jk) == type(^id, ^pk_type)
      )

  defp join_taggings(_, pk_types, _, _, _),
    do: raise("#{__MODULE__} does not support #{inspect(pk_types)} as primary key type.")

  defp pkey_type(schema),
    do:
      :primary_key
      |> schema.__schema__()
      |> Enum.map(&schema.__schema__(:type, &1))
end
