defmodule Ripple.StationsTest do
  use Ripple.DataCase

  alias Ripple.Stations

  describe "stations" do
    alias Ripple.Stations.Station

    @valid_attrs %{
      name: "some name",
      play_type: "public",
      tags: []
    }
    @valid_attrs_with_slug %{name: "with slug", slug: "test-room", play_type: "public", tags: []}
    @invalid_attrs %{name: nil, play_type: nil, tags: nil}

    def station_fixture(attrs \\ %{}) do
      {:ok, user} = Ripple.Users.create_user(%{username: "tester"})

      {:ok, station} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Map.put(:creator_id, user.id)
        |> Stations.create_station()

      station
    end

    test "list_stations/0 returns empty array when no station are live" do
      station_fixture()
      assert Stations.list_stations() == []
    end

    test "get_station!/1 returns the station with given slug when no stations are live" do
      station = station_fixture()
      assert Stations.get_station!(station.slug) == station
    end

    test "create_station/1 with valid data creates a station" do
      {:ok, user} = Ripple.Users.create_user(%{username: "tester"})

      assert {:ok, %Station{} = station} =
               Stations.create_station(@valid_attrs |> Map.put(:creator_id, user.id))

      assert station.name == "some name"
      assert station.play_type == "public"
      assert station.slug == "some-name"
      assert station.tags == []
    end

    test "create_station/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Stations.create_station(@invalid_attrs)
    end

    test "create_station/1 with valid data but missing creator_id returns error" do
      assert {:error, %Ecto.Changeset{}} = Stations.create_station(@valid_attrs)
    end

    test "create_station/1 ignores provided slug and generates based off provided name" do
      {:ok, user} = Ripple.Users.create_user(%{username: "tester"})

      {:ok, %Station{} = station} =
        Stations.create_station(@valid_attrs_with_slug |> Map.put(:creator_id, user.id))

      assert station.name == "with slug"
      assert station.slug == "with-slug"
    end

    test "create_station/1 returns error changeset for existing slug" do
      station = station_fixture()

      {:error, %Ecto.Changeset{} = changeset} =
        Stations.create_station(@valid_attrs |> Map.put(:creator_id, station.creator_id))

      assert changeset.valid? == false
      assert changeset.errors == [slug: {"has already been taken", []}]
    end

    test "change_station/1 returns a station changeset" do
      station = station_fixture()
      assert %Ecto.Changeset{} = Stations.change_station(station)
    end
  end
end
