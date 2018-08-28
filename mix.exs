defmodule Kryptonite.MixProject do
  use Mix.Project

  def project do
    [
      app: :dymo,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Dymo",
      source_url: "https://github.com/the-missing-link/kryptonite",
      homepage_url: "https://github.com/the-missing-link/kryptonite",
      dialyzer: [plt_add_deps: :project, plt_add_apps: [:public_key]],
      docs: [extras: ~w(README.md)],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: cli_env_for(:test, ~w(
        coveralls coveralls.detail coveralls.html coveralls.json coveralls.post
      )),
      package: package(),
      description: "Dymo is your database labeling companion."
    ]
  end

  def application do
    [
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Dev and Test only.
      {:postgrex, "~> 0.13", only: [:dev, :test]},
      # Dev only.
      {:credo, "~> 0.10", only: :dev},
      {:dialyxir, "~> 0.5", only: :dev},
      {:mix_test_watch, "~> 0.8", only: :dev},
      {:ex_doc, "~> 0.19", only: :dev},
      # Test only.
      {:faker, "~> 0.10", only: :test},
      {:excoveralls, "~> 0.8", only: :test},
      # Everything else.
      {:inflex, "~> 1.10.0"},
      {:ecto, "~> 2.2"}
    ]
  end

  defp cli_env_for(env, tasks) do
    Enum.reduce(tasks, [], &Keyword.put(&2, :"#{&1}", env))
  end

  defp package do
    [
      name: "dymo",
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Pierre Martin"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/the-missing-link/dymo"}
    ]
  end
end
