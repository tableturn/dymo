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

  @type label :: Tagger.label()
  @type labels :: Tagger.labels()
  @type join_table :: Tagger.join_table()
  @type join_key :: Tagger.join_key()

  @doc """
  Sets the labels associated with an instance of a model.

  If any other labels are associated to the given model, they are
  discarded if they are not part of the list of passed new labels.

  ## Examples

      iex> labels = ~w(one two)
      iex> %{tags: tags} = %Dymo.Post{title: "Hey"}
      ...>  |> Dymo.repo().insert!
      ...>  |> TaggerImpl.set_labels(labels)
      iex> Enum.map(tags, & &1.label)
      ["one", "two"]
  """
  @spec set_labels(Schema.t(), label() | labels()) :: Schema.t()
  def set_labels(%{tags: %NotLoaded{}} = struct, lbls),
    do:
      struct
      |> Dymo.repo().preload(:tags)
      |> set_labels(lbls)

  def set_labels(%{id: _, tags: _} = struct, lbls),
    do:
      lbls
      |> List.wrap()
      |> maintain_labels_tags(struct)

  @doc """
  Adds labels to a given instance of a model.

  ## Examples

      iex> labels = ~w(three four)
      iex> %{tags: tags} = %Dymo.Post{title: "Hey"}
      ...>  |> Dymo.repo().insert!
      ...>  |> TaggerImpl.set_labels(labels)
      ...>  |> TaggerImpl.add_labels("five")
      iex> Enum.map(tags, & &1.label)
      ["three", "four", "five"]
  """
  @spec add_labels(Schema.t(), label() | labels()) :: Schema.t()
  def add_labels(%{tags: %NotLoaded{}} = struct, lbls),
    do:
      struct
      |> Dymo.repo().preload(:tags)
      |> add_labels(lbls)

  def add_labels(%{id: _, tags: _} = struct, lbls),
    do:
      struct
      |> labels()
      |> Kernel.++(List.wrap(lbls))
      |> maintain_labels_tags(struct)

  @doc """
  Removes labels from a given instance of a model.

  ## Examples

      iex> labels = ~w(six seven)
      iex> %{tags: tags} = %Dymo.Post{title: "Hey"}
      ...>  |> Dymo.repo().insert!
      ...>  |> TaggerImpl.set_labels(labels)
      ...>  |> TaggerImpl.remove_labels("six")
      iex> Enum.map(tags, & &1.label)
      ["seven"]
  """
  @spec remove_labels(Schema.t(), label() | labels()) :: Schema.t()
  def remove_labels(%{tags: %NotLoaded{}} = struct, lbls),
    do:
      struct
      |> Dymo.repo().preload(:tags)
      |> remove_labels(lbls)

  def remove_labels(%{id: _, tags: _} = struct, lbls),
    do:
      struct
      |> labels()
      |> Kernel.--(List.wrap(lbls))
      |> maintain_labels_tags(struct)

  @doc """
  Retrieves labels associated with an target. The target
  could be either a module or a schema.

  ## Examples

      iex> labels = ~w(eight nine)
      iex> post = %Dymo.Post{title: "Hey"}
      ...>  |> Dymo.repo().insert!
      ...>  |> TaggerImpl.set_labels(labels)
      iex> "posts_tags"
      ...>  |> TaggerImpl.query_labels(:post_id)
      ...>  |> Dymo.repo().all()
      false
      iex> post
      ...>  |> TaggerImpl.query_labels()
      ...>  |> Dymo.repo().all()
      ["eight", "nine"]
      iex> post
      ...>  |> TaggerImpl.query_labels("posts_tags", :post_id)
      ...>  |> Dymo.repo().all()
      ["eight", "nine"]
  """
  @spec query_labels(join_table, join_key) :: Query.t()
  def query_labels(jt, jk) when is_binary(jt) and is_atom(jk),
    do:
      Tag
      |> join(:left, [t], tg in ^jt, on: t.id == tg.tag_id)
      |> distinct([t, tg], tg.tag_id)
      |> where([t, tg], not is_nil(field(tg, ^jk)))
      |> order_by([t, tg], asc: t.label)
      |> select([t, tg], t.label)

  @doc """
  Retrieves labels associated with an target.

  See `query_labels/1`
  """
  @spec query_labels(Schema.t(), join_table, join_key) :: Ecto.Query.t()
  def query_labels(%{id: id, tags: _}, jt, jk),
    do:
      Tag
      |> join(:inner, [t], tg in ^jt, on: t.id == tg.tag_id and field(tg, ^jk) == ^id)
      |> distinct([t, tg], t.label)
      |> select([t, tg], t.label)

  @doc """
  Queries models that are tagged with the given labels.

  ## Examples

      iex> labels = ~w(ten eleven)
      iex> %{id: id} = %Dymo.Post{title: "Hey"}
      ...>  |> Dymo.repo().insert!
      ...>  |> TaggerImpl.set_labels(labels)
      iex> id == Dymo.Post
      ...>  |> TaggerImpl.query_labeled_with("ten", "posts_tags", :post_id)
      ...>  |> Dymo.repo().all()
      ...>  |> hd
      ...>  |> Map.get(:id)
      true
      iex> Dymo.Post
      ...>  |> TaggerImpl.query_labeled_with("nothing", "posts_tags", :post_id)
      ...>  |> Dymo.repo().all()
      []
  """
  @spec query_labeled_with(module, label() | labels(), join_table(), join_key()) :: Query.t()
  def query_labeled_with(module, lbl_or_lbls, jt, jk) when is_binary(jt) and is_atom(jk) do
    lbls = List.wrap(lbl_or_lbls)
    lbls_length = length(lbls)

    module
    |> join(:inner, [m], tg in ^jt, on: m.id == field(tg, ^jk))
    |> join(:inner, [m, tg], t in Tag, on: t.id == tg.tag_id)
    |> where([m, tg, t], t.label in ^lbls)
    |> group_by([m, tg, t], m.id)
    |> having([m, tg, t], count(field(tg, ^jk)) == ^lbls_length)
    |> order_by([m, tg, t], asc: m.inserted_at)
  end

  @spec labels(Schema.t()) :: labels()
  def labels(%{id: _, tags: _} = struct),
    do:
      struct
      |> Dymo.repo().preload(:tags)
      |> Map.get(:tags)
      |> Enum.map(& &1.label)

  @spec maintain_labels_tags(labels(), Schema.t()) :: Schema.t()
  defp maintain_labels_tags(lbls, struct),
    do:
      struct
      |> change
      |> put_assoc(:tags, Tag.find_or_create!(lbls))
      |> Dymo.repo().update!()
end
