defmodule Dymo.Repo.Migrations.CreateUUPosts do
  use Ecto.Migration

  def change do
    create table(:uuposts, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string, null: false
      add :body, :string
      timestamps()
    end
  end
end
