use Mix.Config

# The repo configuration should be taken from the environment in priority.
config :dymo,
       Dymo.Repo,
       adapter: Ecto.Adapters.Postgres,
       pool_size: 10,
       hostname: System.get_env("POSTGRES_HOST") || "localhost",
       username: System.get_env("POSTGRES_USER") || "postgres",
       password: System.get_env("POSTGRES_PASSWORD") || "postgres",
       database: System.get_env("POSTGRES_DB") || "dymo_dev"

config :dymo, :repo, Dymo.Repo

config :logger, :console, format: "[$level] $message\n"
