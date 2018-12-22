defmodule Ripple.StationHistoryTest do
  use Ripple.DataCase

  alias Ripple.Stations
  alias Ripple.Stations.StationTrackHistory

  describe "Station History" do
    setup do
      {:ok, user} = Ripple.Users.upsert_user(%{username: "tester"})

      {:ok, station} =
        Ripple.Stations.create_station(%{
          creator_id: user.id,
          name: "test-station",
          tags: [],
          visibility: "public"
        })

      track = Ripple.Tracks.get_or_create_track("https://www.youtube.com/watch?v=4Rc-NGWEHdU")

      %{user: user, station: station, track: track}
    end

    test "add_track_to_history/3 works for valid arguments", context do
      {:ok, %StationTrackHistory{}} =
        Stations.add_track_to_history(context.station.id, context.user.id, context.track.id)
    end

    test "add_track_to_history/3 fails for invalid station_id", context do
      assert_raise Ecto.ChangeError, fn ->
        Stations.add_track_to_history("invalid", context.user.id, context.track.id)
      end
    end

    test "add_track_to_history/3 fails for invalid user_id", context do
      assert_raise Ecto.ChangeError, fn ->
        Stations.add_track_to_history(context.station.id, "invalid", context.track.id)
      end
    end

    test "add_track_to_history/3 fails for invalid track_id", context do
      assert {:error, %Ecto.Changeset{}} =
               Stations.add_track_to_history(context.station.id, context.user.id, "invalid")
    end

    test "mark_track_as_finished/1 successfully sets a track to finished", context do
      Stations.add_track_to_history(context.station.id, context.user.id, context.track.id)

      {:ok, empty} = Stations.get_history(context.station.slug)
      assert Enum.count(empty) == 0

      Stations.mark_track_as_finished(context.station.id)
      {:ok, history} = Stations.get_history(context.station.slug)
      assert Enum.count(history) == 1
    end

    test "mark_track_as_finished/1 does nothing when station does not have a current track",
         context do
      assert {0, nil} = Stations.mark_track_as_finished(context.station.id)
    end

    test "mark_track_as_finished/1 fails for invalid station id" do
      assert_raise Ecto.Query.CastError, fn ->
        Stations.mark_track_as_finished("invalid")
      end
    end

    test "get_history/1 returns empty for station with no history", context do
      assert {:ok, []} = Stations.get_history(context.station.slug)
    end

    test "get_history/1 returns history for station", context do
      Stations.add_track_to_history(context.station.id, context.user.id, context.track.id)

      {:ok, empty} = Stations.get_history(context.station.slug)
      assert Enum.count(empty) == 0

      Stations.mark_track_as_finished(context.station.id)

      {:ok, history} = Stations.get_history(context.station.slug)
      first = List.first(history)
      assert first.dj.id == context.user.id
      assert first.url == context.track.url
    end

    test "get_history/1 returns error when station id is invalid" do
      assert {:error, :not_found} == Stations.get_history("invalid")
    end

    test "get_history/2 returns empty for station with no history", context do
      assert {:ok, []} = Stations.get_history(context.station.slug, DateTime.utc_now())
    end

    test "get_history/2 returns history for station older than provided timestamp", context do
      Stations.add_track_to_history(context.station.id, context.user.id, context.track.id)
      Process.sleep(1000)
      Stations.mark_track_as_finished(context.station.id)
      Process.sleep(1000)
      Stations.add_track_to_history(context.station.id, context.user.id, context.track.id)
      Process.sleep(1000)
      Stations.mark_track_as_finished(context.station.id)

      {:ok, history} = Stations.get_history(context.station.slug)
      first = List.first(history)
      {:ok, older} = Stations.get_history(context.station.slug, first.finished_at)
      assert Enum.count(older) == 1
      assert List.first(older).started_at < first.started_at
      assert List.first(older).finished_at < first.finished_at
    end

    test "get_history/2 returns error when station id is invalid" do
      assert {:error, :not_found} == Stations.get_history("invalid")
    end
  end
end
