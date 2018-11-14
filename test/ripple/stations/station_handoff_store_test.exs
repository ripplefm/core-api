defmodule Ripple.StationHandoffStoreTest do
  use Ripple.DataCase

  alias Ripple.Stations.{StationHandoffStore, LiveStation}

  @valid_attrs %{
    play_type: "public",
    tags: []
  }

  describe "StationHandoffStore" do
    def station_fixture(username, station_name) do
      {:ok, user} = Ripple.Users.create_user(%{username: username})

      {:ok, station} =
        %{}
        |> Enum.into(@valid_attrs)
        |> Map.put(:name, station_name)
        |> Map.put(:creator_id, user.id)
        |> Ripple.Stations.create_station()

      live_station = %LiveStation{
        id: station.id,
        name: station.name,
        play_type: station.play_type,
        slug: station.slug,
        guests: 0,
        users: [user],
        current_track: nil,
        queue: [],
        creator_id: user.id
      }

      %{
        station: live_station,
        user: user
      }
    end

    setup do
      :mnesia.clear_table(StationHandoffStore)
      station_fixture("tester", "Test Station")
    end

    test "Ensure station handoff store started" do
      assert StationHandoffStore in :mnesia.system_info(:tables)
    end

    test "put/1 successfully inserts new station", %{station: station} do
      assert :ok == StationHandoffStore.put(station)
      [{_, _, saved_station, _}] = :mnesia.dirty_read(StationHandoffStore, station.slug)
      assert saved_station == station
    end

    test "put/1 succesfully replaces station with same slug", %{station: station} do
      assert :ok == StationHandoffStore.put(station)
      new_station = Map.put(station, :guests, 1)
      assert :ok == StationHandoffStore.put(new_station)
      [{_, _, saved_station, _}] = :mnesia.dirty_read(StationHandoffStore, station.slug)
      assert saved_station == new_station
    end

    test "put/1 errors when argument not a station" do
      assert_raise FunctionClauseError,
                   "no function clause matching in Ripple.Stations.StationHandoffStore.put/1",
                   fn ->
                     StationHandoffStore.put(%{this_is: "not a station"})
                   end
    end

    test "put/1 does nothing when attempting to put nil" do
      assert :ok == StationHandoffStore.put(nil)
      assert :mnesia.table_info(StationHandoffStore, :size) == 0
    end

    test "get_and_delete/1 succesfully returns and deletes a station", %{station: station} do
      assert :ok == StationHandoffStore.put(station)
      assert {:ok, saved_station} = StationHandoffStore.get_and_delete(station.slug)
      assert saved_station == station
      assert :mnesia.table_info(StationHandoffStore, :size) == 0
    end

    test "get_and_delete/1 errors when station with slug not in store" do
      assert {:error, :no_exists} == StationHandoffStore.get_and_delete("no-exists")
    end
  end
end
