defmodule Ripple.StationStoreSyncTest do
  use ExUnit.ClusteredCase, async: false

  alias Ripple.Stations.StationStore

  @opts [cluster_size: 3, boot_timeout: 10_000]

  defdelegate node_setup(context), to: Ripple.ClusterHelper

  scenario "Healthy cluster", @opts do
    setup %{cluster: c} do
      on_exit(fn ->
        c |> Cluster.random_member() |> Cluster.call(Ripple.ClusterHelper, :cleanup, [])
      end)

      %{
        node_setup: Ripple.ClusterHelper.create_config()
      }
    end

    node_setup(:node_setup)

    test "Horde cluster station store sync supervisors initialized", %{cluster: c} do
      counts =
        Cluster.map(c, fn ->
          {:ok, horde_cluster} = Horde.Cluster.members(Ripple.StationStoreSyncSupervisor)
          Enum.count(horde_cluster)
        end)

      assert List.duplicate(@opts[:cluster_size], @opts[:cluster_size]) == counts
    end

    test "Distributed mnesia successfully running on nodes", %{cluster: c} do
      node = Cluster.random_member(c)

      erlang_nodes = Cluster.members(c)
      mnesia_nodes = Cluster.call(node, :mnesia, :system_info, [:running_db_nodes])
      assert erlang_nodes -- mnesia_nodes == []

      assert List.duplicate(0, @opts[:cluster_size]) ==
               Cluster.map(c, :mnesia, :table_info, [:live_stations, :size])
    end

    test "StationStoreSync restarts when killed", %{cluster: c} do
      node = Cluster.random_member(c)

      assert [[{"station_store_sync", first_pid, _, _}]] =
               Cluster.call(node, Horde.Supervisor, :which_children, [
                 Ripple.StationStoreSyncSupervisor
               ])

      Cluster.call(node, Process, :exit, [first_pid, :exit])

      assert [[{"station_store_sync", second_pid, _, _}]] =
               Cluster.call(node, Horde.Supervisor, :which_children, [
                 Ripple.StationStoreSyncSupervisor
               ])

      assert first_pid != second_pid
    end

    test "Station Store data is accurate if station crashes without emitting event", %{cluster: c} do
      cluster_size = c |> Cluster.members() |> Enum.count()
      node = Cluster.random_member(c)

      {:ok, user} =
        Cluster.call(node, Ripple.Users, :upsert_user, [%{username: "cluster_tester"}])

      {:ok, station} =
        Cluster.call(node, Ripple.Stations, :create_station, [
          %{creator_id: user.id, name: "Test Station", play_type: "public", tags: []}
        ])

      {:ok, _pid} = Cluster.call(node, Ripple.Stations.StationServer, :start, [station, user])

      assert List.duplicate(1, cluster_size) == Cluster.map(c, StationStore, :num_stations, [])

      # kill station server without emitting event
      Cluster.call(node, Horde.Supervisor, :terminate_child, [
        Ripple.StationSupervisor,
        "stations:#{station.slug}"
      ])

      # wait for horde crdts to sync and for station store sync
      Process.sleep(5_000)

      assert List.duplicate(0, cluster_size) == Cluster.map(c, StationStore, :num_stations, [])
    end
  end
end
