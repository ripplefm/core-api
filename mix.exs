defmodule Ripple.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ripple,
      version: "0.2.1",
      elixir: "~> 1.7.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Ripple.Application, []},
      extra_applications: [:logger, :runtime_tools, :httpoison, :canada]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:joken, "~> 1.5.0"},
      {:canary, "~> 1.1.1"},
      {:httpoison, "~> 1.0"},
      {:slugify, "~> 1.1.0"},
      {:event_bus, "~> 1.0.0"},
      {:cors_plug, "~> 1.2"},
      {:distillery, "~> 2.0"},
      {:libcluster, "~> 3.0"},
      {:horde, "~> 0.2.2"},
      {:lbm_kv, "~> 0.0.2"},
      {:ex_unit_clustered_case, "~> 0.3.2", only: [:test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
