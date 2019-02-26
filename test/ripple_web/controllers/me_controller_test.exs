defmodule RippleWeb.MeControllerTest do
  use RippleWeb.ConnCase

  alias Ripple.Stations
  alias Ripple.Playlists

  @create_attrs %{name: "Some station", tags: [], visibility: "public"}

  def station_fixture() do
    {:ok, user} =
      case Ripple.Users.get_user("tester") do
        {:error, :not_found} -> Ripple.Users.create_user(%{username: "tester"})
        u -> {:ok, u}
      end

    {:ok, station} =
      @create_attrs
      |> Map.put(:creator_id, user.id)
      |> Stations.create_station()

    station
  end

  def playlist_fixture() do
    {:ok, user} =
      case Ripple.Users.get_user("tester") do
        {:error, :not_found} -> Ripple.Users.create_user(%{username: "tester"})
        u -> {:ok, u}
      end

    {:ok, playlist} =
      Playlists.create_playlist(%{
        creator_id: user.id,
        name: "some playlist",
        tags: [],
        visibility: "public"
      })

    playlist
  end

  def token_fixture do
    %{
      scopes: ["user:read"],
      user: %{id: Ecto.UUID.generate(), username: "tester"}
    }
    |> RippleWeb.Helpers.JWTHelper.sign()
  end

  describe "show_created_stations" do
    test "401 when missing authorization header", %{conn: conn} do
      conn = get(conn, me_path(conn, :show_created_stations))
      assert conn.status == 401
      assert(conn.assigns.current_user == nil)
    end

    test "401 when token missing 'stations:read' scope", %{conn: conn} do
      token = token_fixture()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(me_path(conn, :show_created_stations))

      assert ["Bearer #{token}"] == get_req_header(conn, "authorization")

      assert json_response(conn, 401) == %{
               "errors" => %{"detail" => "Invalid scopes for resource."}
             }
    end

    @tag :authenticated
    test "returns created stations when authenticated", %{conn: conn} do
      station_fixture()
      conn = conn |> get(me_path(conn, :show_created_stations))

      assert json_response(conn, 200)["stations"] != []
    end
  end

  describe "show_following_stations" do
    test "401 when missing authorization header", %{conn: conn} do
      conn = get(conn, me_path(conn, :show_following_stations))
      assert conn.status == 401
      assert(conn.assigns.current_user == nil)
    end

    test "401 when token missing 'stations:read' scope", %{conn: conn} do
      token = token_fixture()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(me_path(conn, :show_following_stations))

      assert ["Bearer #{token}"] == get_req_header(conn, "authorization")

      assert json_response(conn, 401) == %{
               "errors" => %{"detail" => "Invalid scopes for resource."}
             }
    end

    @tag :authenticated
    test "returns following stations when authenticated", %{conn: conn} do
      user = Ripple.Users.get_user("tester")
      station = station_fixture()
      {:ok, _} = Stations.follow_station(station, user)
      conn = conn |> get(me_path(conn, :show_following_stations))

      assert json_response(conn, 200)["stations"] != []
    end
  end

  describe "show_created_playlists" do
    test "401 when missing authorization header", %{conn: conn} do
      conn = get(conn, me_path(conn, :show_created_playlists))
      assert conn.status == 401
      assert(conn.assigns.current_user == nil)
    end

    test "401 when token missing 'playlists:read' scope", %{conn: conn} do
      token = token_fixture()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(me_path(conn, :show_created_playlists))

      assert ["Bearer #{token}"] == get_req_header(conn, "authorization")

      assert json_response(conn, 401) == %{
               "errors" => %{"detail" => "Invalid scopes for resource."}
             }
    end

    @tag :authenticated
    test "returns created playlists when authenticated", %{conn: conn} do
      user = Ripple.Users.get_user("tester")
      playlist = playlist_fixture()
      {:ok, _} = Playlists.follow_playlist(playlist, user)
      conn = conn |> get(me_path(conn, :show_created_playlists))

      assert json_response(conn, 200)["playlists"] != []
    end
  end

  describe "show_following_playlists" do
    test "401 when missing authorization header", %{conn: conn} do
      conn = get(conn, me_path(conn, :show_following_playlists))
      assert conn.status == 401
      assert(conn.assigns.current_user == nil)
    end

    test "401 when token missing 'playlists:read' scope", %{conn: conn} do
      token = token_fixture()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(me_path(conn, :show_following_playlists))

      assert ["Bearer #{token}"] == get_req_header(conn, "authorization")

      assert json_response(conn, 401) == %{
               "errors" => %{"detail" => "Invalid scopes for resource."}
             }
    end

    @tag :authenticated
    test "returns following playlists when authenticated", %{conn: conn} do
      user = Ripple.Users.get_user("tester")
      playlist = playlist_fixture()
      {:ok, _} = Playlists.follow_playlist(playlist, user)
      conn = conn |> get(me_path(conn, :show_following_playlists))

      assert json_response(conn, 200)["playlists"] != []
    end
  end
end
