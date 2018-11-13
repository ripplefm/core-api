defmodule Ripple.StationSupervisorTest do
  # use Ripple.ClusterCase, cluster_size: 3
  use ExUnit.ClusteredCase, async: false

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

    test "Horde cluster station supervisors initialized", %{cluster: c} do
      counts =
        Cluster.map(c, fn ->
          {:ok, horde_cluster} = Horde.Cluster.members(Ripple.StationSupervisor)
          Enum.count(horde_cluster)
        end)

      assert List.duplicate(@opts[:cluster_size], @opts[:cluster_size]) == counts
    end

    test "Horde cluster station registry initialized", %{cluster: c} do
      counts =
        Cluster.map(c, fn ->
          {:ok, horde_cluster} = Horde.Cluster.members(Ripple.StationRegistry)
          Enum.count(horde_cluster)
        end)

      assert List.duplicate(@opts[:cluster_size], @opts[:cluster_size]) == counts
    end

    test "Station server started on random node", %{cluster: c} do
      node = Cluster.random_member(c)

      {:ok, user} =
        Cluster.call(node, Ripple.Users, :upsert_user, [%{username: "cluster_tester"}])

      {:ok, station} =
        Cluster.call(node, Ripple.Stations, :create_station, [
          %{creator_id: user.id, name: "Test Station", play_type: "public", tags: []}
        ])

      {:ok, pid} = Cluster.call(node, Ripple.Stations.StationServer, :start, [station, user])

      Process.sleep(2_000)

      assert %{active: 1} =
               Cluster.call(node, Horde.Supervisor, :count_children, [Ripple.StationSupervisor])

      assert pid ==
               Cluster.call(node, Horde.Registry, :lookup, [
                 Ripple.StationRegistry,
                 "stations:#{station.slug}"
               ])
    end

    test "Station server not restarted when properly exited", %{cluster: c} do
      node = Cluster.random_member(c)

      {:ok, user} =
        Cluster.call(node, Ripple.Users, :upsert_user, [%{username: "cluster_tester"}])

      {:ok, station} =
        Cluster.call(node, Ripple.Stations, :create_station, [
          %{creator_id: user.id, name: "Test Station", play_type: "public", tags: []}
        ])

      Cluster.call(node, Ripple.Stations.StationServer, :start, [station, user])

      Process.sleep(1_000)

      Cluster.call(node, Ripple.Stations.StationServer, :remove_user, [station.slug, user])

      Process.sleep(1_000)

      assert %{} =
               Cluster.call(node, Horde.Supervisor, :count_children, [Ripple.StationSupervisor])

      assert :undefined ==
               Cluster.call(node, Horde.Registry, :lookup, [
                 Ripple.StationRegistry,
                 "stations:#{station.slug}"
               ])
    end

    test "Station server restarted when killed/crashed", %{cluster: c} do
      node = Cluster.random_member(c)

      {:ok, user} =
        Cluster.call(node, Ripple.Users, :upsert_user, [%{username: "cluster_tester"}])

      {:ok, station} =
        Cluster.call(node, Ripple.Stations, :create_station, [
          %{creator_id: user.id, name: "Test Station", play_type: "public", tags: []}
        ])

      {:ok, first_pid} =
        Cluster.call(node, Ripple.Stations.StationServer, :start, [station, user])

      Cluster.call(node, Process, :exit, [first_pid, :normal])

      Process.sleep(2_000)

      second_pid =
        Cluster.call(node, Horde.Registry, :lookup, [
          Ripple.StationRegistry,
          "stations:#{station.slug}"
        ])

      assert second_pid != first_pid
    end
  end
end
