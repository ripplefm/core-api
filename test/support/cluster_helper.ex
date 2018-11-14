defmodule Ripple.ClusterHelper do
  alias ExUnit.ClusteredCase.Cluster

  # Ran on master node to save config to map sent to node_setup/1 and ran on each node
  def create_config() do
    loaded_applications = Application.loaded_applications()

    configs =
      for {app_name, _, _} <- loaded_applications do
        app_configs =
          for {key, val} <- Application.get_all_env(app_name) do
            {key, val}
          end

        Map.put(%{}, app_name, app_configs)
      end

    application_configs =
      Enum.reduce(configs, %{}, fn app_config, acc -> Map.merge(acc, app_config) end)

    %{
      code_paths: :code.get_path(),
      mix_env: Mix.env(),
      loaded_applications: loaded_applications,
      application_configs: application_configs
    }
  end

  def cleanup() do
    Ripple.Repo.delete_all(Ripple.Stations.Station)
    Ripple.Repo.delete_all(Ripple.Users.User)
    Ripple.Repo.delete_all(Ripple.Tracks.Track)

    stations = Horde.Supervisor.which_children(Ripple.StationSupervisor)

    stations
    |> Enum.map(&List.first/1)
    |> Enum.map(&elem(&1, 0))
    |> Enum.each(&Horde.Supervisor.terminate_child(Ripple.StationSupervisor, &1))

    :mnesia.clear_table(Ripple.Stations.StationStore)
    :mnesia.clear_table(Ripple.Stations.StationHandoffStore)
  end

  def heal(cluster) do
    Cluster.heal(cluster)

    for node <- Cluster.members(cluster) do
      for other <- Cluster.call(node, Node, :list, []) do
        Cluster.call(node, Ripple.ClusterConnector, :connect, [other])
      end
    end

    # sleep for horde crdts to sync
    Process.sleep(5_000)
  end

  # Set up each node in the cluster to load env and start applications
  def node_setup(%{node_setup: node_setup}) do
    :code.add_paths(node_setup[:code_paths])
    transfer_configuration(node_setup[:loaded_applications], node_setup[:application_configs])
    ensure_applications_started(node_setup[:loaded_applications], node_setup[:mix_env])
    Enum.each(Node.list(), &Ripple.ClusterConnector.connect/1)
    # sleep for horde crdts to sync
    Process.sleep(2_000)
    Ecto.Adapters.SQL.Sandbox.mode(Ripple.Repo, {:shared, self()})
  end

  defp transfer_configuration(loaded_applications, application_configs) do
    for {app_name, _, _} <- loaded_applications do
      for {key, val} <- Map.get(application_configs, app_name) do
        Application.put_env(app_name, key, val)
      end
    end
  end

  defp ensure_applications_started(loaded_applications, mix_env) do
    Application.ensure_all_started(:mix)
    Mix.env(mix_env)

    for {app_name, _, _} <- loaded_applications do
      Application.ensure_all_started(app_name)
    end
  end
end
