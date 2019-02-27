defmodule Ripple.ReleaseTasks do
  @start_apps [
    :ripple,
    :crypto,
    :ssl,
    :postgrex,
    :ecto
  ]

  def migrate(_argv) do
    start_services()

    run_migrations()

    stop_services()
  end

  def seed(_argv) do
    start_services()

    run_seeds()

    stop_services()
  end

  defp repos do
    Application.get_env(:ripple, :ecto_repos, [])
  end

  defp start_services do
    IO.puts("Starting dependencies..")
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for app
    IO.puts("Starting repos..")
    Enum.each(repos(), & &1.start_link(pool_size: 1))
  end

  defp stop_services do
    IO.puts("Success!")
    :init.stop()
  end

  defp run_migrations do
    Enum.each(repos(), &run_migrations_for/1)
  end

  def run_seeds do
    Enum.each(repos(), &run_seeds_for/1)
  end

  defp run_migrations_for(repo) do
    app = Keyword.get(repo.config, :otp_app)
    IO.puts("Running migrations for #{app}")
    migrations_path = priv_path_for(repo, "migrations")
    Ecto.Migrator.run(repo, migrations_path, :up, all: true)
  end

  defp run_seeds_for(repo) do
    seed_script = priv_for_path(repo, "seeds/seeds.exs")

    if File.exists?(seed_script) do
      IO.puts("Running seed script #{seed_script}")
      Code.eval_file(seed_script)
    end
  end

  defp priv_path_for(repo, filename) do
    app = Keyword.get(repo.config, :otp_app)

    repo_underscore =
      repo
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    priv_dir = "#{:code.priv_dir(app)}"

    Path.join([priv_dir, repo_underscore, filename])
  end
end
