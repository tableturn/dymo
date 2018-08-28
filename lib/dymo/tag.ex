defmodule Dymo.Tag do
  @moduledoc """
  This module provides functionality dedicated to handling user data.
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

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(attrs),
    do:
      %@me{}
      |> cast(attrs, [:label])
      |> validate_required([:label])
      |> unique_constraint(:label)

  @doc """
  This function gets an existing tag using its label. If the tag doesn't
  exit, it is atomically created.
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
