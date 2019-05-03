defmodule Dymo.TaggerImpl do
  @moduledoc """
  This tagger helps with tagging objects using a backed ecto repo.
  """

  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Ecto.{Schema, Query}
  alias Ecto.Association.NotLoaded
  alias Dymo.{Tag, Tagger}

  @behaviour Tagger

  @type join_table :: Tagger.join_table()
  @type join_key :: Tagger.join_key()

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
  @spec set_labels(Schema.t(), Tag.ns(), Tag.label() | [Tag.label()]) :: Schema.t()
  def set_labels(struct, ns \\ nil, lbls)

  def set_labels(%{tags: %NotLoaded{}} = struct, ns, lbls) do
    struct
    |> Dymo.repo().preload(:tags)
    |> set_labels(ns, lbls)
  end

  def set_labels(%{id: _, tags: tags} = struct, ns, lbls) do
    ns = Tag.Ns.cast!(ns)

    tags
    |> group_by_ns()
    |> Map.put(ns, List.wrap(lbls))
    |> flatten()
    |> maintain_labels_tags(struct)
  end

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
  @spec add_labels(Schema.t(), Tag.ns(), Tag.label_or_labels()) :: Schema.t()
  def add_labels(struct, ns \\ nil, lbls)

  def add_labels(%{tags: %NotLoaded{}} = struct, ns, lbls) do
    struct
    |> Dymo.repo().preload(:tags)
    |> add_labels(ns, lbls)
  end

  def add_labels(%{id: _, tags: tags} = struct, ns, lbls) do
    lbls
    |> List.wrap()
    |> Enum.map(&Tag.cast({ns, &1}))
    |> Enum.concat(tags)
    |> maintain_labels_tags(struct)
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
  @spec remove_labels(Schema.t(), Tag.ns(), Tag.label() | Tag.labels()) :: Schema.t()
  def remove_labels(struct, ns \\ nil, lbls)

  def remove_labels(%{tags: %NotLoaded{}} = struct, ns, lbls) do
    struct
    |> Dymo.repo().preload(:tags)
    |> remove_labels(ns, lbls)
  end

  def remove_labels(%{id: _, tags: tags} = struct, ns, lbls) do
    ns = Tag.Ns.cast!(ns)

    tags
    |> group_by_ns()
    |> Map.update(ns, [], &(&1 -- List.wrap(lbls)))
    |> flatten()
    |> maintain_labels_tags(struct)
  end

  @doc """
  Generates query for retrieving labels associated with a schema.

  ## Examples

      iex> labels = ~w(eight nine)
      iex> post = %Dymo.Post{title: "Hey"}
      ...>  |> Dymo.repo().insert!
      ...>  |> TaggerImpl.set_labels(:number, labels)
      iex> "posts_tags"
      ...>  |> TaggerImpl.query_all_labels(:post_id, :number)
      ...>  |> Dymo.repo().all()
      ["eight", "nine"]
  """
  @spec query_all_labels(join_table, join_key, Tag.ns()) :: Query.t()
  def query_all_labels(jt, jk, ns \\ nil) when is_binary(jt) and is_atom(jk) do
    Tag
    |> join(:left, [t], tg in ^jt, on: t.id == tg.tag_id)
    |> distinct([t, tg], tg.tag_id)
    |> where([t, tg], not is_nil(field(tg, ^jk)))
    |> where_ns(Tag.Ns.cast!(ns))
    |> order_by([t, tg], asc: t.label)
    |> select([t, tg], t.label)
  end

  @doc """
  Generates query for retrieving labels associated with a schema's
  instance.
  """
  @spec query_labels(Schema.t(), join_table, join_key, Tag.ns()) :: Query.t()
  def query_labels(%{id: id, tags: _}, jt, jk, ns \\ nil) do
    Tag
    |> join(:inner, [t], tg in ^jt, on: t.id == tg.tag_id and field(tg, ^jk) == ^id)
    |> where_ns(Tag.Ns.cast!(ns))
    |> distinct([t, tg], t.label)
    |> select([t, tg], t.label)
  end

  @doc """
  Queries models that are tagged with the given labels.

  ## Examples

      iex> labels = ~w(ten eleven)
      iex> %{id: id} = %Dymo.Post{title: "Hey"}
      ...>  |> Dymo.repo().insert!
      ...>  |> TaggerImpl.set_labels(:number, labels)
      iex> id == Dymo.Post
      ...>  |> TaggerImpl.query_labeled_with({:number, "ten"}, "posts_tags", :post_id)
      ...>  |> Dymo.repo().all()
      ...>  |> hd
      ...>  |> Map.get(:id)
      true
      iex> Dymo.Post
      ...>  |> TaggerImpl.query_labeled_with({:unknown, "nothing"}, "posts_tags", :post_id)
      ...>  |> Dymo.repo().all()
      []
  """
  @spec query_labeled_with(module, Tag.tag_or_tags(), join_table(), join_key()) :: Query.t()
  def query_labeled_with(module, tag_or_tags, jt, jk) when is_binary(jt) and is_atom(jk) do
    {nss, lbls} =
      tag_or_tags
      |> List.wrap()
      |> Enum.map(&Tag.cast/1)
      |> Enum.reduce({[], []}, fn tag, {nss, lbls} -> {[tag.ns | nss], [tag.label | lbls]} end)

    tags_length = length(lbls)

    module
    |> join(:inner, [m], tg in ^jt, on: m.id == field(tg, ^jk))
    |> join(:inner, [m, tg], t in Tag, on: t.id == tg.tag_id)
    |> where([m, tg, t], t.label in ^lbls)
    |> where([m, tg, t], t.ns in ^nss)
    |> group_by([m, tg, t], m.id)
    |> having([m, tg, t], count(field(tg, ^jk)) == ^tags_length)
    |> order_by([m, tg, t], asc: m.inserted_at)
  end

  @spec labels(Schema.t(), Tag.ns()) :: [Tag.label()]
  def labels(%{id: _, tags: _} = struct, ns \\ nil) do
    ns = Tag.Ns.cast!(ns)

    struct
    |> Dymo.repo().preload(:tags)
    |> Map.get(:tags)
    |> Enum.filter(&(&1.ns == ns))
    |> Enum.map(& &1.label)
  end

  @spec maintain_labels_tags([Tag.t()], Schema.t()) :: Schema.t()
  defp maintain_labels_tags(tags, struct) do
    struct
    |> change
    |> put_assoc(:tags, Tag.find_or_create!(tags))
    |> Dymo.repo().update!()
  end

  defp group_by_ns(tags) when is_list(tags), do: Enum.group_by(tags, & &1.ns, & &1.label)

  defp flatten(tags) when is_map(tags) do
    Enum.reduce(tags, [], fn {ns, lbls}, acc ->
      lbls
      |> Enum.map(&Tag.cast({ns, &1}))
      |> Enum.concat(acc)
    end)
  end

  defp where_ns(q, ns), do: where(q, [t, tg], t.ns == ^ns)
end
