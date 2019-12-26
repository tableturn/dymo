defmodule Dymo.Post do
  @moduledoc false

  use Ecto.Schema
  use Dymo.Taggable, join_table: "taggings"

  alias Ecto.{Changeset, Schema}
  import Ecto.Changeset

  @type t :: %__MODULE__{}
  schema "posts" do
    tags()
    field :title, :string
    field :body, :string
    timestamps()
  end

  @spec struct :: t()
  def struct, do: %__MODULE__{}

  @spec changeset(t | Changeset.t(), map) :: Ecto.Changeset.t()
  def changeset(struct, attrs),
    do:
      struct
      |> cast(attrs, [:title, :body])
      |> validate_required([:title])
end
