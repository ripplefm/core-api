defmodule Ripple.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec
    # Define workers and child supervisors to be supervised
    app_children = [
      # Start the Ecto repository
      supervisor(Ripple.Repo, []),
      # Start the endpoint when the application starts
      supervisor(RippleWeb.Endpoint, []),
      # Start station echo
      worker(RippleWeb.Broadcasters.StationBroadcaster, [], restart: :permanent),
      # Start your own worker by calling: Ripple.Worker.start_link(arg1, arg2, arg3)
      # worker(Ripple.Worker, [arg1, arg2, arg3]),
      {Horde.Registry, name: Ripple.StationRegistry},
      {Horde.Supervisor, name: Ripple.StationSupervisor, strategy: :one_for_one, children: []},
      {Horde.Supervisor,
       name: Ripple.StationStoreSyncSupervisor,
       strategy: :one_for_one,
       id: Ripple.StationStoreSyncSupervisor}
    ]

    children =
      if System.get_env("CLUSTER_ENABLED") == "true" do
        topologies = Application.get_env(:libcluster, :topologies)

        app_children ++
          [
            {Cluster.Supervisor, [topologies, [name: Ripple.ClusterSupervisor]]}
          ]
      else
        app_children
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ripple.Supervisor]
    result = Supervisor.start_link(children, opts)
    Ripple.Stations.StationStoreSync.start()
    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    RippleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
