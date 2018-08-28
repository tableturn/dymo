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
    |> Path.join("#{Utils.timestamp()}_create_tag.exs")
    |> create_file("""
    defmodule Repo.Migrations.CreateTags do
      use Ecto.Migration

      def change do
      create table(:tags) do
        add :label, :string, null: false

        timestamps()
      end

      create index(:tags, [:label], unique: true)
      end
    end
    """)
  end
end
