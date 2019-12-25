defmodule Dymo.Tag do
  @moduledoc """
  This module provides functionality dedicated to handling tag data.

  It essentially aims at maintaining singleton labels in a `tags` table
  and exposes helper functions to ease their creation.
  """

  use Ecto.Schema
  import Ecto.Query

  alias Dymo.Tag.Ns
  alias Ecto.Changeset

  @me __MODULE__

  @typedoc "Defines simple tags identified by a unique label."
  @type t :: %__MODULE__{}

  @typedoc "Maps to `Ns.t()`."
  @type ns :: Ns.t()
  @typedoc "Defines a string or a list of strings."
  @type string_or_strings :: raw_label | [raw_label]
  @typedoc "Defines a namespaced label."
  @type raw_label :: String.t()
  @typedoc "Defines a namespaced label."
  @type namespaced_label :: {ns, raw_label}
  @typedoc "Defines a tag's label, namespaced or not."
  @type label :: raw_label | namespaced_label
  @typedoc "Defines a single flat label or a list of labels, namespaced or not."
  @type label_or_labels :: label | [label]

  @typedoc "Defines attributes for building this model's changeset"
  @type attrs :: %{
          optional(:ns) => ns,
          required(:label) => raw_label
        }

  schema "tags" do
    # Regular fields.
    field :label, :string
    field :ns, Ns, default: Ns.root_namespace()
    timestamps()
  end

  @spec tuppleify(label | t) :: namespaced_label
  def tuppleify({ns, lbl}) do
    {:ok, cast_ns} = Ns.cast(ns)
    {cast_ns, lbl}
  end

  def tuppleify(%{ns: ns, label: lbl}), do: tuppleify({ns, lbl})
  def tuppleify(lbl) when is_binary(lbl), do: tuppleify({Ns.root_namespace(), lbl})

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
  @spec changeset(label | attrs()) :: Ecto.Changeset.t()
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
    |> Changeset.cast(sanitized_params, [:ns, :label])
    |> Changeset.validate_required([:ns, :label])
    |> Changeset.unique_constraint(:label, name: :tags_unicity)
  end

  # Called with just a %{label: label}.
  def changeset(%{label: label}),
    do: changeset(%{ns: Ns.root_namespace(), label: label})

  @doc """
  Casts attributes into a `Tag` struct.
  """
  @spec cast(label_or_labels | t() | Changeset.t()) :: t
  def cast(%@me{} = struct),
    do: struct

  def cast(stuff) do
    stuff
    |> changeset()
    |> case do
      %{valid?: true} = cs -> Changeset.apply_changes(cs)
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
        returning: false
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
      |> where([t], t.ns == ^ns and t.label == ^label)
      |> Dymo.repo().one()
end
