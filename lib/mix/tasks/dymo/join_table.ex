defmodule Mix.Tasks.Dymo.JoinTable do
  @shortdoc "Generates Dymo join table between a model and Tags."

  use Mix.Task
  import Mix.Generator
  alias Dymo.Tagger
  alias Mix.Tasks.Dymo.Utils

  def run([]), do: raise("No model module name specified.")

  def run([model]) do
    if String.length(model) <= 0 do
      raise "Please specify a full model module name as this task argument."
    end

    # Eg: Elixir.Dymo.Post.
    module = ["Elixir", model] |> Enum.join(".") |> String.to_existing_atom()
    # Eg: "Post"
    singular = module |> Module.split() |> List.last()
    # Eg: "post"
    singular_downcase = String.downcase(singular)
    # Eg: Posts
    plural = singular |> Inflex.pluralize()
    # Eg: posts
    plural_downcase = plural |> String.downcase()
    # Eg: posts_tags.
    table = Tagger.join_table(module)
    # Eg: post_id
    key = Tagger.join_key(module)

    path = Path.relative_to("priv/repo/migrations", Mix.Project.app_path())
    create_directory path

    path
    |> Path.join("#{Utils.timestamp()}_create_#{table}.exs")
    |> create_file("""
    defmodule Repo.Migrations.Create#{plural}Tags do
      use Ecto.Migration

      def change do
        create table(:#{table}, primary_key: false) do
          add :#{key}, references(:#{plural_downcase})
          add :tag_id, references(:tags)
        end

        create index(:#{table}, [:tag_id])
        create index(:#{table}, [:#{singular_downcase}_id])
        create index(:#{table}, [:tag_id, :#{key}], unique: true)
      end
    end
    """)

    IO.puts("""
    Once your database gets migrated, a new table #{table} will be created.
    You might want to add the following relationship to your #{model} schema:
      many_to_many :tags, Dymo.Tag,
                    join_through: \"#{table}\",
                    on_replace: :delete,
                    unique: true
    """)
  end
end
