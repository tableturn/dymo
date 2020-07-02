defmodule Dymo.Tag do
  @moduledoc """
  This module provides functionality dedicated to handling tag data.

  It essentially aims at maintaining singleton labels in a `tags` table
  and exposes helper functions to ease their creation.
  """
  use Ecto.Schema
  alias Dymo.Tag.Ns
  alias Ecto.Changeset
  import Ecto.{Query, Changeset}

  @me __MODULE__

  @typedoc "Defines simple tags identified by a unique label."
  @type t :: %__MODULE__{}

  @typedoc "Defines a namespaced label."
  @type namespaced_label :: {Ns.t(), String.t()}
  @typedoc "Defines a tag's label, namespaced or not."
  @type label :: String.t() | namespaced_label
  @typedoc "Defines a single flat label or a list of labels, namespaced or not."
  @type label_or_labels :: label | [label]

  @typedoc "Defines attributes for building this model's changeset"
  @type creation_attrs :: %{
          optional(:ns) => Ns.t(),
          optional(:assignable) => boolean,
          required(:label) => String.t()
        }

  schema "tags" do
    # Regular fields.
    field :ns, Ns, default: Ns.root_namespace()
    field :label, :string
    field :assignable, :boolean, default: true
    timestamps()
  end

  @doc """
  Makes a changeset suited to manipulate the `Tag` model.

  ## Examples

      iex> "blue"
      ...>   |> changeset()
      ...>   |> Changeset.apply_changes()
      ...>   |> Map.take([:ns, :label])
      %{ns: Ns.root_namespace(), label: "blue"}

      iex> {:paint, "blue"}
      ...>   |> changeset()
      ...>   |> Changeset.apply_changes()
      ...>   |> Map.take([:ns, :label])
      %{ns: :paint, label: "blue"}

      iex> {"car", "blue"}
      ...>   |> changeset()
      ...>   |> Changeset.apply_changes()
      ...>   |> Map.take([:ns, :label])
      %{ns: :car, label: "blue"}

      iex> %{ns: :car, label: "blue"}
      ...>   |> changeset()
      ...>   |> Changeset.apply_changes()
      ...>   |> Map.take([:ns, :label])
      %{ns: :car, label: "blue"}

      iex> {"non existent", "blue"}
      ...>   |> changeset()
      ...>   |> Map.take([:valid?])
      %{valid?: false}
  """
  @spec changeset(label | creation_attrs()) :: Changeset.t()
  # Called for a given string label.
  def changeset(label) when is_binary(label),
    do: changeset(%{label: label})

  # Called for a given namespace and label.
  def changeset({ns, label}) when is_binary(label),
    do: changeset(%{ns: ns, label: label})

  # Called with a proper %{ns: ns, label: label}.
  def changeset(attrs) when is_map(attrs) do
    # We sanitize params by forcing a value into the namespace in
    # case it's nil or not existent.
    ns = Map.get(attrs, :ns) || Ns.root_namespace()
    sanitized_params = attrs |> Map.put(:ns, ns)

    %@me{}
    |> cast(sanitized_params, [:ns, :label, :assignable])
    |> validate_required([:ns, :label])
    |> unique_constraint(:label, name: :tags_unicity)
  end

  # Called with just a %{label: label}.
  def changeset(%{label: label}),
    do: changeset(%{ns: Ns.root_namespace(), label: label})

  @doc """
  Casts attributes into a `Tag` struct.
  """
  @spec to_struct(label_or_labels | t() | Changeset.t()) :: t
  def to_struct(%@me{} = struct),
    do: struct

  def to_struct(stuff) do
    stuff
    |> changeset()
    |> case do
      %{valid?: true} = cs -> cs |> apply_changes()
      _ -> raise "Parametters cannot be cast into a tag: #{inspect(stuff)}"
    end
  end

  @doc """
  This function gets an existing tag using its label. If the tag doesn't
  exit, it is atomically created. It could be described as a "singleton"
  helper.

  ## Examples

      iex> %{id: id1a} = Tag.find_or_create!("novel")
      ...> [%{id: id2a}, %{id: id3a}] = Tag.find_or_create!(["article", "book"])
      ...> [%{id: id1b}, %{id: id2b}, %{id: id3b}] = Tag.find_or_create!(["novel", "article", "book"])
      ...> {id1a, id2a, id3a} == {id1b, id2b, id3b}
      true

      iex> %{id: id4a} = Tag.find_or_create!({:romance, "novel"})
      ...> [%{id: id5a}, %{id: id6a}] = Tag.find_or_create!([{:romance, "article"}, {:scifi, "book"}])
      ...> [%{id: id4b}, %{id: id5b}, %{id: id6b}] = Tag.find_or_create!([{:romance, "novel"}, {:romance, "article"}, {:scifi, "book"}])
      ...> {id4a, id5a, id6a} == {id4b, id5b, id6b}
      true
  """
  @spec find_or_create!(label_or_labels | t) :: label_or_labels
  def find_or_create!(labels) when is_list(labels),
    do:
      labels
      |> Enum.uniq()
      |> Enum.map(&find_or_create!/1)

  def find_or_create!(label) when is_binary(label),
    do: find_or_create!({Ns.root_namespace(), label})

  def find_or_create!(%{ns: ns, label: label}),
    do: find_or_create!({ns, label})

  def find_or_create!({_, _} = label),
    do:
      label
      |> changeset()
      |> Dymo.repo().insert!(
        on_conflict: {:replace, [:updated_at]},
        conflict_target: [:ns, :label],
        returning: [:ns, :label, :assignable]
      )

  @doc """
  This function gets an existing tag using its label. If the tag doesn't
  exit, it is atomically created. It could be described as a "singleton"
  helper.

  ## Examples

      iex> %{id: id1a} = Tag.find_or_create!("novel")
      ...> [%{id: id1b}, other] = Tag.find_existing(["novel", "book"])
      ...> {id1a, nil} == {id1b, other}
      true

      iex> %{id: id1a} = Tag.find_or_create!({:romance, "novel"})
      ...> [%{id: id1b}, other] = Tag.find_existing([{:romance, "novel"}, {:scifi, "book"}])
      ...> {id1a, nil} == {id1b, other}
      true
  """
  @spec find_existing(label_or_labels | t | [t]) :: label_or_labels
  def find_existing(tags) when is_list(tags),
    do:
      tags
      |> Enum.uniq()
      |> Enum.map(&find_existing/1)

  def find_existing(label) when is_binary(label),
    do: find_existing({Ns.root_namespace(), label})

  def find_existing(%{ns: ns, label: label}),
    do: find_existing({ns, label})

  def find_existing({ns, label}),
    do:
      @me
      |> where([t], t.assignable and t.ns == ^ns and t.label == ^label)
      |> Dymo.repo().one()
end
