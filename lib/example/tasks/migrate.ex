defmodule Example.Tasks.Migrate do
  @moduledoc false
  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto
  ]

  def migrate(_args) do
    # Configure
    Mix.Releases.Config.Providers.Elixir.init(["${RELEASE_ROOT_DIR}/etc/config.exs"])
    repo_config = Application.get_env(:distillery_example, Example.Repo)
    hostname = Keyword.get(repo_config, :hostname)
    database = Keyword.get(repo_config, :database)
    username = Keyword.get(repo_config, :username)
    password = Keyword.get(repo_config, :password)
    # IO.inspect {:migrate, hostname, database, username, password}
    repo_config = Keyword.put(repo_config, :adapter, Ecto.Adapters.Postgres)
    Application.put_env(:distillery_example, Example.Repo, repo_config)

    # Start requisite apps
    IO.puts "==> Starting applications.."
    for app <- @start_apps do
      {:ok, res} = Application.ensure_all_started(app)
      IO.puts "==> Started #{app}: #{inspect res}"
    end

    # Start the repo
    IO.puts "==> Starting repo"
    {:ok, _pid} = Example.Repo.start_link(pool_size: 1, log: true, log_sql: true)

    # Run the migrations for the repo
    IO.puts "==> Running migrations"
    priv_dir = Application.app_dir(:distillery_example, "priv")
    migrations_dir = Path.join([priv_dir, "repo", "migrations"])

    opts = [all: true]
    pool = Example.Repo.config[:pool]
    if function_exported?(pool, :unboxed_run, 2) do
      pool.unboxed_run(Example.Repo, fn -> Ecto.Migrator.run(Example.Repo, migrations_dir, :up, opts) end)
    else
      Ecto.Migrator.run(Example.Repo, migrations_dir, :up, opts)
    end

    # seed_app = Application.app_dir(:distillery_example)
    # command = Path.expand(Path.join([seed_app, "..", "..", "bin", "seed_zone_info"]))
    # IO.inspect {:load_command, command}
    # System.cmd(command, [hostname, database, username, password])

    # Shut down
    :init.stop()
  end
end
