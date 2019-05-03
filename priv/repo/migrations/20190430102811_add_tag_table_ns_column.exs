defmodule Dymo.Repo.Migrations.AddTagTableNsColumn do
  use Ecto.Migration

  def change do
    alter table(:tags) do
      add :ns, :string
    end

    drop index(:tags, [:label])
    create index(:tags, [:label, :ns], unique: true, name: :tags_unique)
  end
end
