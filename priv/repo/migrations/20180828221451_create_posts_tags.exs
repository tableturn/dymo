defmodule Repo.Migrations.CreatePostsTags do
  use Ecto.Migration

  def change do
    create table(:posts_tags, primary_key: false) do
      add :post_id, references(:posts)
      add :tag_id, references(:tags)
    end

    create index(:posts_tags, [:tag_id])
    create index(:posts_tags, [:post_id])
    create index(:posts_tags, [:tag_id, :post_id], unique: true)
  end
end
