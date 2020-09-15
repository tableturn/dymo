defmodule Mix.Tasks.Dymo.Install do
  @moduledoc false
  @shortdoc "Generates Dymo migration file for the Tag model."

  use Mix.Task
  import Mix.Generator
  alias Mix.Tasks.Dymo.Utils

  def run(_args) do
    path = Path.relative_to("priv/repo/migrations", Mix.Project.app_path())
    create_directory path

    path
    |> Path.join("#{Utils.timestamp()}_create_tags.exs")
    |> create_file("""
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

        create index(:tags, [:ns, :label], unique: true, name: :tags_unicity)
      end
    end
    """)
  end
end
