defmodule Dymo.Repo.Migrations.CreateTaggings do
  use Ecto.Migration

  @unique_fields ~w(tag_id post_id uu_post_id)a
  @taggings_constraint "num_nonnulls(post_id, uu_post_id) = 1"

  def change do
    create table(:taggings, primary_key: false) do
      # Reference to the tag itself.
      add :tag_id, references(:tags)
      # Reference to each taggables.
      add :post_id, references(:posts)
      add :uu_post_id, references(:uuposts, type: :uuid)
    end

    # Index the tag ID column for fast joins.
    create index(:taggings, [:tag_id])
    # Each taggable model should be indexed as well.
    create index(:taggings, [:post_id])
    create index(:taggings, [:uu_post_id])

    # A single entity can only be tagged once with a given tag, enforce uniqueness with this index.
    create unique_index(:taggings, @unique_fields, name: :taggings_uniqueness)
    # This constraint ensures that only one column is set on any given tagging.
    create constraint(:taggings, :must_reference_one, check: @taggings_constraint)
  end
end
