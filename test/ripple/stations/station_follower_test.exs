defmodule Ripple.StationFollowerTest do
  use Ripple.DataCase

  alias Ripple.Stations
  alias Ripple.Stations.StationFollower

  describe "Station Followers" do
    setup do
      {:ok, user} = Ripple.Users.upsert_user(%{username: "tester"})

      {:ok, station} =
        Ripple.Stations.create_station(%{
          creator_id: user.id,
          name: "test-station",
          tags: [],
          visibility: "public"
        })

      %{user: user, station: station}
    end

    test "follow_station/2 successfully follows a station", %{station: station, user: user} do
      {:ok, %StationFollower{} = f} = Stations.follow_station(station, user)

      assert f.user_id == user.id
      assert f.station_id == station.id

      {:ok, s} = Stations.get_station(station.slug)
      assert s.followers == 1
    end

    test "follow_station/2 returns error when already following", %{station: station, user: user} do
      {:ok, %StationFollower{}} = Stations.follow_station(station, user)
      assert {:error, :already_following} == Stations.follow_station(station, user)
    end

    test "unfollow_station/2 sucessfully unfollows a station", %{station: station, user: user} do
      {:ok, %StationFollower{}} = Stations.follow_station(station, user)

      {:ok, s} = Stations.get_station(station.slug)
      assert s.followers == 1

      assert :ok == Stations.unfollow_station(station, user)

      {:ok, s} = Stations.get_station(station.slug)
      assert s.followers == 0
    end

    test "unfollow_station/2 returns error when not following station", %{
      station: station,
      user: user
    } do
      assert {:error, :not_following} == Stations.unfollow_station(station, user)
    end

    test "is_followed_by?/2 returns true when following station", %{station: station, user: user} do
      {:ok, _} = Stations.follow_station(station, user)
      assert Stations.is_followed_by?(station, user) == true
    end

    test "is_followed_by?/2 returns false when not following station", %{
      station: station,
      user: user
    } do
      assert Stations.is_followed_by?(station, user) == false
    end
  end
end
