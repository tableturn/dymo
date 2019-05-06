defmodule Dymo.Post do
  @moduledoc false

  use Ecto.Schema
  use Dymo.Taggable

  import Ecto.Changeset
  alias Ecto.{Changeset, Schema}

  @type t :: %__MODULE__{}
  schema "posts" do
    tags taggings: "posts_tags"

    # Regular fields.
    field :title, :string
    field :body, :string

    timestamps()
  end

  @spec changeset(t | Changeset.t(), map) :: Ecto.Changeset.t()
  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:title, :body])
    |> validate_required([:title])
  end
end
