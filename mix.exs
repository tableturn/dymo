defmodule Dymo.MixProject do
  use Mix.Project

  def project(),
    do: [
      app: :dymo,
      version: "3.0.4",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Dymo",
      source_url: "https://github.com/tableturn/dymo",
      homepage_url: "https://github.com/tableturn/dymo",
      dialyzer: [
        plt_add_deps: :transitive,
        plt_add_apps: [:mix, :ecto]
      ],
      docs: [extras: ~w(README.md)],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: cli_env_for(:test, ~w(
        coveralls coveralls.detail coveralls.html coveralls.json coveralls.post
          )),
      consolidate_protocols: Mix.env() != :test,
      package: package(),
      description: "Dymo is your database labeling companion."
    ]

  def application(),
    do: [
      extra_applications: [:logger, :runtime_tools]
    ]

  defp elixirc_paths(:test),
    do: ["lib", "test/support"]

  defp elixirc_paths(_),
    do: ["lib"]

  defp deps(),
    do: [
      # Dev and Test only.
      {:ecto_sql, "~> 3.3", only: [:dev, :test]},
      {:postgrex, "~> 0.14", only: [:dev, :test]},
      # Dev only.
      {:credo, "~> 1.1", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.19", only: [:dev, :test, :docs]},
      # Test only.
      {:excoveralls, "~> 0.8", only: :test},
      # Everything else.
      {:ecto, "~> 3.4"},
      {:inflex, "~> 2.0"}
    ]

  defp cli_env_for(env, tasks),
    do: Enum.reduce(tasks, [], &Keyword.put(&2, :"#{&1}", env))

  defp package(),
    do: [
      name: "dymo",
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Pierre Martin", "Jean Parpaillon"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/tableturn/dymo"}
    ]
end
