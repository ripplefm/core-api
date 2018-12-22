defmodule RippleWeb.StationFollowerControllerTest do
  use RippleWeb.ConnCase

  alias Ripple.Stations

  @create_attrs %{name: "some name", visibility: "public", tags: []}

  def station_fixture do
    {:ok, user} = Ripple.Users.upsert_user(%{username: "test"})
    {:ok, station} = Stations.create_station(@create_attrs |> Map.put(:creator_id, user.id))
    station
  end

  def token_fixture do
    %{
      scopes: ["user:read", "stations:read"],
      user: %{id: Ecto.UUID.generate(), username: "tester"}
    }
    |> RippleWeb.Helpers.JWTHelper.sign()
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create" do
    test "401 when missing authorization header", %{conn: conn} do
      conn = post(conn, station_follower_path(conn, :create, "slug"))
      assert conn.status == 401
      assert conn.assigns.current_user == nil
    end

    test "401 when missing access token missing 'stations:write' scope", %{conn: conn} do
      token = token_fixture()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(station_follower_path(conn, :create, "slug"))

      assert ["Bearer #{token}"] == get_req_header(conn, "authorization")

      assert json_response(conn, 401) == %{
               "errors" => %{"detail" => "Invalid scopes for resource."}
             }
    end

    @tag :authenticated
    test "201 when succesfully followed a station", %{conn: conn} do
      station = station_fixture()
      conn = post(conn, station_follower_path(conn, :create, station.slug))

      assert conn.status == 201
    end

    @tag :authenticated
    test "404 when trying to follow nonexistent station", %{conn: conn} do
      conn = post(conn, station_follower_path(conn, :create, "invalid"))

      assert json_response(conn, 404) == %{
               "errors" => %{"detail" => "Page not found"}
             }
    end

    @tag :authenticated
    test "422 when already following station", %{conn: conn} do
      user = Ripple.Users.get_user!("tester")
      station = station_fixture()
      Stations.follow_station(station, user)
      conn = post(conn, station_follower_path(conn, :create, station.slug))

      assert json_response(conn, 422) == %{
               "errors" => %{"detail" => "Already following station"}
             }
    end
  end

  describe "delete" do
    test "401 when missing authorization header", %{conn: conn} do
      conn = delete(conn, station_follower_path(conn, :delete, "slug"))
      assert conn.status == 401
      assert conn.assigns.current_user == nil
    end

    test "401 when missing access token missing 'stations:write' scope", %{conn: conn} do
      token = token_fixture()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(station_follower_path(conn, :delete, "slug"))

      assert ["Bearer #{token}"] == get_req_header(conn, "authorization")

      assert json_response(conn, 401) == %{
               "errors" => %{"detail" => "Invalid scopes for resource."}
             }
    end

    @tag :authenticated
    test "204 when successfully unfollowed a station", %{conn: conn} do
      user = Ripple.Users.get_user!("tester")
      station = station_fixture()
      {:ok, _} = Stations.follow_station(station, user)

      conn = delete(conn, station_follower_path(conn, :delete, station.slug))

      assert conn.status == 204
    end

    @tag :authenticated
    test "404 when trying to unfollow nonexistent station", %{conn: conn} do
      conn = delete(conn, station_follower_path(conn, :delete, "invalid"))

      assert json_response(conn, 404) == %{
               "errors" => %{"detail" => "Page not found"}
             }
    end

    @tag :authenticated
    test "422 when trying to unfollow station thats not followed", %{conn: conn} do
      station = station_fixture()
      conn = delete(conn, station_follower_path(conn, :delete, station.slug))

      assert json_response(conn, 422) == %{
               "errors" => %{"detail" => "Not following station"}
             }
    end
  end
end
