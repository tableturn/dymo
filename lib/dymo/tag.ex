defmodule Dymo.Tag do
  @moduledoc """
  This module provides functionality dedicated to handling tag data.

  It essentially aims at maintaining singleton labels in a `tags` table
  and exposes helper functions to ease their creation.
  """

  use Ecto.Schema

  alias Dymo.Tag.Ns
  alias Ecto.Changeset

  @me __MODULE__

  @typedoc "Defines simple tags identified by a unique label."
  @type t :: %__MODULE__{}
  @type ns :: Ns.t()

  @typedoc "Defines a string or a list of strings."
  @type string_or_strings :: String.t() | [String.t()]
  @typedoc "Defines a tag's label"
  @type label :: String.t() | {ns(), String.t()}
  @typedoc "Defines a single flat label or a list of labels."
  @type label_or_labels :: label | [label]

  @typedoc "Defines attributes for building this model's changeset"
  @type changeset_attrs :: %{
          optional(:ns) => ns(),
          required(:label) => String.t()
        }

  schema "tags" do
    # Regular fields.
    field :label, :string
    field :ns, Ns, default: []
    timestamps()
  end

  @doc """
  Makes a changeset suited to manipulate the `Dymo.Tag` model.

  ## Examples

      iex> cs = changeset("blue")
      ...> with %Changeset{valid?: true} <- cs, do: :ok
      :ok

      iex> cs = changeset({:paint, "blue"})
      ...> with %Changeset{valid?: true} <- cs, do: :ok
      :ok

      iex> cs = changeset({[:paint, :car], "blue"})
      ...> with %Changeset{valid?: true} <- cs, do: :ok
      :ok

      iex> cs = changeset({"car", "blue"})
      ...> with %Changeset{valid?: false} <- cs, do: :error
      :error

      iex> cs = changeset(%{ns: :car, label: "blue"})
      ...> with %Changeset{valid?: true} <- cs, do: :ok
      :ok
  """
  @spec changeset(label | changeset_attrs()) :: Ecto.Changeset.t()
  # Called for a given string label.
  def changeset(label) when is_binary(label), do: changeset(%{label: label})
  # Called for a nil namespace and a label.
  def changeset({nil, label}) when is_binary(label), do: changeset(%{ns: [], label: label})
  # Called for a given namespace and label.
  def changeset({ns, label}) when is_binary(label), do: changeset(%{ns: ns, label: label})
  # Called with a proper %{ns: ns, label: label}
  def changeset(attrs) when is_map(attrs),
    do:
      %@me{}
      |> Changeset.cast(attrs, [:ns, :label])
      |> Changeset.validate_required([:ns, :label])
      |> Changeset.unique_constraint(:label, name: :tags_unique)

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
      ...> [%{id: id5a}, %{id: id6a}] = Tag.find_or_create!([{:romance, "article"}, {:sf, "book"}])
      ...> [%{id: id4b}, %{id: id5b}, %{id: id6b}] = Tag.find_or_create!([{:romance, "novel"}, {:romance, "article"}, {:sf, "book"}])
      ...> {id4a, id5a, id6a} == {id4b, id5b, id6b}
      true
  """
  @spec find_or_create!(label_or_labels) :: label_or_labels
  def find_or_create!(tags) when is_list(tags),
    do:
      tags
      |> Enum.map(&cast/1)
      |> Enum.uniq()
      |> Enum.map(&find_or_create!/1)

  def find_or_create!(tag),
    do:
      tag
      |> cast()
      |> Dymo.repo().insert!(
        on_conflict: {:replace, [:updated_at]},
        conflict_target: [:ns, :label],
        returning: false
      )

  def cast(%@me{} = struct), do: struct

  def cast(stuff) do
    stuff
    |> changeset()
    |> case do
      %Changeset{valid?: false} -> raise "Invalid tag: #{inspect(stuff)}"
      %Changeset{valid?: true} = cs -> Changeset.apply_changes(cs)
    end
  end
end
