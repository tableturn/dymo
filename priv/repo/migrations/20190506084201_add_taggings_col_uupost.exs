defmodule Dymo.Repo.Migrations.AddTaggingsColUupost do
  use Ecto.Migration

  def change do
    alter table(:posts_tags) do
      add :uu_post_id, references(:uuposts, type: :uuid)
    end

    drop index(:posts_tags, [:tag_id, :post_id], unique: true)

    create index(:posts_tags, [:tag_id, :post_id, :uu_post_id], unique: true)
  end
end
