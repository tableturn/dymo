defmodule Dymo.UUPost do
  @moduledoc false

  use Ecto.Schema
  use Dymo.Taggable, join_table: "posts_tags"

  alias Ecto.Changeset
  alias Ecto.Schema

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "uuposts" do
    tags()

    field :title, :string
    field :body, :string

    timestamps()
  end

  def changeset(struct, attrs) do
    struct
    |> Changeset.cast(attrs, [:title, :body])
    |> Changeset.validate_required([:title])
  end
end
