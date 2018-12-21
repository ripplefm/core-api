defmodule RippleWeb.StationHistoryControllerTest do
  use RippleWeb.ConnCase

  alias Ripple.Stations

  @create_attrs %{name: "some name", visibility: "public", tags: []}
  @track_url "https://www.youtube.com/watch?v=4Rc-NGWEHdU"

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  def fixture do
    {:ok, user} = Ripple.Users.create_user(%{username: "tester"})
    {:ok, station} = Stations.create_station(@create_attrs |> Map.put(:creator_id, user.id))
    track = Ripple.Tracks.get_or_create_track(@track_url)
    %{station: station, user: user, track: track}
  end

  describe "show" do
    test "404 when station does not exist", %{conn: conn} do
      conn = get(conn, station_history_path(conn, :show, "invalid"))
      assert %{"errors" => %{"detail" => "Page not found"}} == json_response(conn, 404)
    end

    test "renders empty history for station with no history", %{conn: conn} do
      %{station: station} = fixture()
      conn = get(conn, station_history_path(conn, :show, station.slug))
      assert [] == json_response(conn, 200)
    end

    test "renders history for station with history", %{conn: conn} do
      %{station: station, user: user, track: track} = fixture()
      Stations.add_track_to_history(station.id, user.id, track.id)
      Stations.mark_track_as_finished(station.id)
      conn = get(conn, station_history_path(conn, :show, station.slug))
      history = json_response(conn, 200)
      assert Enum.count(history) == 1
    end

    test "last_timestamp param allows pagination", %{conn: conn} do
      %{station: station, user: user, track: track} = fixture()
      Stations.add_track_to_history(station.id, user.id, track.id)
      Stations.mark_track_as_finished(station.id)

      {:ok, h} = Stations.get_history(station.slug)

      conn =
        get(conn, station_history_path(conn, :show, station.slug), %{
          last_timestamp: List.first(h).finished_at
        })

      assert [] == json_response(conn, 200)
    end
  end
end
