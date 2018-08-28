defmodule Dymo.Tag do
  @moduledoc """
  This module provides functionality dedicated to handling tag data.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @me __MODULE__
  @repo Dymo.repo()

  @type id :: pos_integer

  @typedoc """
  The `Dymo.Tag.t()` schema defines simple tags identified by
  a unique label.
  """
  @type t :: %__MODULE__{}
  schema "tags" do
    # Regular fields.
    field(:label, :string)
    timestamps()
  end

  @doc """
  Makes a changeset suited to manipulate the `Dymo.Tag` model.
  """
  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(attrs),
    do:
      %@me{}
      |> cast(attrs, [:label])
      |> validate_required([:label])
      |> unique_constraint(:label)

  @doc """
  This function gets an existing tag using its label. If the tag doesn't
  exit, it is atomically created. It could be described as a "singleton"
  helper.

  ## Examples

      iex> %{id: id1a} = Tag.find_or_create!("novel")
      iex> [%{id: id2a}, %{id: id3a}] = Tag.find_or_create!(["article", "book"])
      iex> [%{id: id1b}, %{id: id2b}, %{id: id3b}] = Tag.find_or_create!(["novel", "article", "book"])
      iex> {id1a, id2a, id3a} == {id1b, id2b, id3b}
      true
  """
  @spec find_or_create!(String.t() | [String.t()]) :: t
  def find_or_create!(labels) when is_list(labels),
    do:
      labels
      |> Enum.uniq()
      |> Enum.map(&find_or_create!/1)

  def find_or_create!(label) do
    @me
    |> @repo.get_by(label: label)
    |> case do
      nil -> upsert!(label)
      tag -> tag
    end
  end

  @spec upsert!(String.t()) :: t
  defp upsert!(label) do
    %{label: label}
    |> changeset()
    |> @repo.insert!(on_conflict: :nothing)
    |> case do
      %{id: nil} -> @repo.get_by!(@me, label: label)
      tag -> tag
    end
  end
end
