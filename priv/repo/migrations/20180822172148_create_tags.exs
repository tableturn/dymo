defmodule Dymo.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add(:label, :string, null: false)

      timestamps()
    end

    create(index(:tags, [:label], unique: true))
  end
end
