defmodule Ripple.StationsTest do
  use Ripple.DataCase

  alias Ripple.Stations

  describe "stations" do
    alias Ripple.Stations.Station

    @valid_attrs %{name: "some name", play_type: "some play_type", slug: "some slug", tags: []}
    @update_attrs %{name: "some updated name", play_type: "some updated play_type", slug: "some updated slug", tags: []}
    @invalid_attrs %{name: nil, play_type: nil, slug: nil, tags: nil}

    def station_fixture(attrs \\ %{}) do
      {:ok, station} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Stations.create_station()

      station
    end

    test "list_stations/0 returns all stations" do
      station = station_fixture()
      assert Stations.list_stations() == [station]
    end

    test "get_station!/1 returns the station with given id" do
      station = station_fixture()
      assert Stations.get_station!(station.id) == station
    end

    test "create_station/1 with valid data creates a station" do
      assert {:ok, %Station{} = station} = Stations.create_station(@valid_attrs)
      assert station.name == "some name"
      assert station.play_type == "some play_type"
      assert station.slug == "some slug"
      assert station.tags == []
    end

    test "create_station/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Stations.create_station(@invalid_attrs)
    end

    test "update_station/2 with valid data updates the station" do
      station = station_fixture()
      assert {:ok, station} = Stations.update_station(station, @update_attrs)
      assert %Station{} = station
      assert station.name == "some updated name"
      assert station.play_type == "some updated play_type"
      assert station.slug == "some updated slug"
      assert station.tags == []
    end

    test "update_station/2 with invalid data returns error changeset" do
      station = station_fixture()
      assert {:error, %Ecto.Changeset{}} = Stations.update_station(station, @invalid_attrs)
      assert station == Stations.get_station!(station.id)
    end

    test "delete_station/1 deletes the station" do
      station = station_fixture()
      assert {:ok, %Station{}} = Stations.delete_station(station)
      assert_raise Ecto.NoResultsError, fn -> Stations.get_station!(station.id) end
    end

    test "change_station/1 returns a station changeset" do
      station = station_fixture()
      assert %Ecto.Changeset{} = Stations.change_station(station)
    end
  end
end
