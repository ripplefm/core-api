defmodule RippleWeb.MeControllerTest do
  use RippleWeb.ConnCase

  alias Ripple.Stations

  @create_attrs %{name: "Some station", tags: [], visibility: "public"}

  def station_fixture(overrides \\ %{}) do
    {:ok, user} =
      case Ripple.Users.get_user("tester") do
        {:error, :not_found} -> Ripple.Users.create_user(%{username: "tester"})
        u -> {:ok, u}
      end

    {:ok, station} =
      Map.merge(@create_attrs, overrides)
      |> Map.put(:creator_id, user.id)
      |> Stations.create_station()

    station
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
end
