defmodule Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :ns, :string, null: false
      add :label, :string, null: false
      add :assignable, :boolean, null: false, default: true

      timestamps()
    end

    create index(:tags, [:label])
    create index(:tags, [:ns])
    create index(:tags, [:assignable])

    create index(:tags, [:label, :ns], unique: true, name: :tags_unicity)
  end
end
