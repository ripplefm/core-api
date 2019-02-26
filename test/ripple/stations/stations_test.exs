defmodule Ripple.StationsTest do
  use Ripple.DataCase

  alias Ripple.Stations

  describe "stations" do
    alias Ripple.Stations.Station

    @valid_attrs %{
      name: "some name",
      visibility: "public",
      tags: []
    }
    @valid_attrs_with_slug %{name: "with slug", slug: "test-room", visibility: "public", tags: []}
    @invalid_attrs %{name: nil, visibility: nil, tags: nil}

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
      assert Stations.list_stations() == {:ok, []}
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
      assert station.visibility == "public"
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

    test "get_stations_created_by/1 returns stations only created by the user" do
      station_created_by_user = station_fixture()
      user = Ripple.Users.get_user("tester")
      {:ok, user2} = Ripple.Users.create_user(%{username: "tester2"})

      {:ok, station_created_by_other} =
        Stations.create_station(%{
          creator_id: user2.id,
          name: "some station 2",
          tags: [],
          visibility: "public"
        })

      results = Stations.get_stations_created_by(user)

      assert results == [station_created_by_user]
      assert station_created_by_other not in results
    end

    test "get_stations_created_by/1 returns public and private stations" do
      public_station = station_fixture()
      user = Ripple.Users.get_user("tester")

      {:ok, private_station} =
        Stations.create_station(%{
          creator_id: user.id,
          name: "private_station",
          tags: [],
          visibility: "private"
        })

      results = Stations.get_stations_created_by(user)

      assert results -- [public_station, private_station] == []
      assert private_station in results
    end

    test "get_stations_followed_by/1 returns stations only followed by the user" do
      station1 = station_fixture()
      user = Ripple.Users.get_user("tester")

      {:ok, station2} =
        Stations.create_station(%{
          creator_id: user.id,
          name: "private_station",
          tags: [],
          visibility: "private"
        })

      {:ok, _} = Stations.follow_station(station1, user)

      results = Stations.get_stations_followed_by(user)
      {:ok, station1} = Stations.get_station(station1.slug)
      assert results == [station1]
      assert station2 not in results
    end

    test "get_stations_followed_by/1 includes public and private stations" do
      station1 = station_fixture()
      user = Ripple.Users.get_user("tester")

      {:ok, station2} =
        Stations.create_station(%{
          creator_id: user.id,
          name: "private_station",
          tags: [],
          visibility: "private"
        })

      {:ok, _} = Stations.follow_station(station1, user)
      {:ok, _} = Stations.follow_station(station2, user)

      results = Stations.get_stations_followed_by(user)
      assert Enum.count(results) == 2
    end
  end
end
