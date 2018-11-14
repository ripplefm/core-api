defmodule Ripple.StationStoreTest do
  use Ripple.DataCase

  alias Ripple.Stations.{StationStore, StationServer}

  @valid_attrs %{
    play_type: "public",
    tags: []
  }

  describe "StationStore" do
    def station_fixture(username, station_name) do
      {:ok, user} = Ripple.Users.create_user(%{username: username})

      {:ok, station} =
        %{}
        |> Enum.into(@valid_attrs)
        |> Map.put(:name, station_name)
        |> Map.put(:creator_id, user.id)
        |> Ripple.Stations.create_station()

      {:ok, pid} = Ripple.Stations.StationServer.start(station, user)
      Process.sleep(100)

      %{
        pid: pid,
        station: station,
        user: user
      }
    end

    setup do
      on_exit(fn ->
        stations = Horde.Supervisor.which_children(Ripple.StationSupervisor)

        stations
        |> Enum.map(&List.first/1)
        |> Enum.map(&elem(&1, 0))
        |> Enum.each(&Horde.Supervisor.terminate_child(Ripple.StationSupervisor, &1))
      end)

      :mnesia.clear_table(StationStore)
      station_fixture("tester", "Test Station")
    end

    test "Ensure station store started" do
      assert StationStore in :mnesia.system_info(:tables)
    end

    test "list_stations/0 returns empty list when no stations are live", %{
      station: station,
      user: user
    } do
      StationServer.remove_user(station.slug, user)
      Process.sleep(100)
      assert {:ok, []} == StationStore.list_stations()
    end

    test "list_stations/0 returns stations sorted by number of users in descending order", %{
      station: station
    } do
      %{station: station2, user: _user} = station_fixture("tester2", "Test Station 2")
      {:ok, user3} = Ripple.Users.create_user(%{username: "tester3"})
      Ripple.Stations.StationServer.add_user(station2.slug, user3)

      {:ok, [first, second]} = StationStore.list_stations()
      assert first.slug == station2.slug
      assert second.slug == station.slug
    end

    test "read/1 returns corresponding station", %{station: station} do
      assert {:ok, station_read} = StationStore.read(station.slug)

      assert station.id == station_read.id
    end

    test "read/1 returns nil when station with slug doesn't exist" do
      assert {:ok, nil} = StationStore.read("no-such-station")
    end

    test "save/1 correctly saves station for new write", %{station: station, user: user} do
      StationServer.remove_user(station.slug, user)
      Process.sleep(100)
      assert {:ok, []} == StationStore.list_stations()
      assert :ok == StationStore.save(station)

      {:ok, read} = StationStore.read(station.slug)
      assert station.id == read.id
    end

    test "save/1 overwrites stations when one with slug already exists with same user count", %{
      station: station,
      user: user
    } do
      {:ok, existing} = StationStore.read(station.slug)

      new_station =
        Map.put(station, :tags, ["testing"]) |> Map.put(:guests, 0) |> Map.put(:users, [user])

      StationStore.save(new_station)

      {:ok, new_saved} = StationStore.read(station.slug)

      assert existing.id == station.id
      assert new_saved.id == existing.id
      assert new_saved.guests == existing.guests
      assert new_saved.tags != existing.tags
    end

    test "save/1 overwrites station when station already exists with different user count", %{
      station: station
    } do
      {:ok, existing} = StationStore.read(station.slug)

      new_station = Map.put(station, :guests, 2)

      StationStore.save(new_station)

      {:ok, new_saved} = StationStore.read(station.slug)

      assert existing.id == station.id
      assert new_saved.id == existing.id
      assert new_saved.guests != existing.guests
    end

    test "delete/1 returns error when station when slug doesn't exist" do
      assert {:error, :no_exists} = StationStore.delete("no-such-station")
    end

    test "delete/1 deletes station", %{station: station} do
      assert {:ok, existing} = StationStore.read(station.slug)
      assert existing.id == station.id

      assert :ok = StationStore.delete(station.slug)

      assert {:ok, nil} = StationStore.read(station.slug)
    end

    test "list_stations/2 returns correct 'slice' of stations" do
    end

    test "num_stations/0 returns correct station count" do
      assert 1 == StationStore.num_stations()
    end

    test "clear_and_save/1 empties store and writes new stations", %{station: station} do
      %{station: station2} = station_fixture("tester2", "Test Station 2")
      assert :ok = StationStore.delete(station.slug)
      assert 1 == StationStore.num_stations()
      assert :ok = StationStore.clear_and_save([station, station2])
      assert 2 == StationStore.num_stations()
    end

    test "station store is updated when a station is updated", %{station: station} do
      assert {:ok, existing} = StationStore.read(station.slug)

      assert existing.id == station.id
      assert existing.guests == 0

      StationServer.add_user(station.slug, nil)
      Process.sleep(100)
      assert {:ok, updated} = StationStore.read(station.slug)
      assert updated.id == station.id
      assert updated.guests == 1
    end
  end
end
