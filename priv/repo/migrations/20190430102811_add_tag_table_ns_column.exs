defmodule Dymo.Repo.Migrations.AddTagTableNsColumn do
  use Ecto.Migration

  def change do
    alter table(:tags) do
      add :ns, {:array, :string}
    end

    create index(:tags, [:ns])
  end
end
