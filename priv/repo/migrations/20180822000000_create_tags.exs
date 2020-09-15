defmodule Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :parent_id, references(:tags, on_delete: :delete_all)
      add :ns, :string, null: false
      add :label, :string, null: false
      add :description, :string
      add :assignable, :boolean, null: false, default: true

      timestamps()
    end

    create index(:tags, [:ns])
    create index(:tags, [:label])
    create index(:tags, [:description])
    create index(:tags, [:assignable])

    create unique_index(:tags, [:ns, :label], name: :tags_uniqueness)
  end
end
