defmodule RippleWeb.StationControllerTest do
  use RippleWeb.ConnCase

  alias Ripple.Stations

  @create_attrs %{name: "some name", play_type: "public", tags: []}
  @invalid_attrs %{name: nil, play_type: nil, tags: nil}

  def fixture(:station) do
    {:ok, user} = Ripple.Users.create_user(%{username: "tester"})
    {:ok, station} = Stations.create_station(@create_attrs |> Map.put(:creator_id, user.id))
    station
  end

  def token_fixture() do
    %{
      scopes: ["user:read", "stations:read"],
      user: %{id: Ecto.UUID.generate(), username: "tester"}
    }
    |> RippleWeb.Helpers.JWTHelper.sign()
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "empty list when no stations are live", %{conn: conn} do
      conn = get(conn, station_path(conn, :index))
      assert json_response(conn, 200)["stations"] == []
    end
  end

  describe "create station" do
    test "401 when missing authorization header", %{conn: conn} do
      conn = post(conn, station_path(conn, :create), station: @create_attrs)
      assert conn.status == 401
      assert conn.assigns.current_user == nil
    end

    test "401 when access token missing 'stations:write' scope", %{conn: conn} do
      token = token_fixture()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(station_path(conn, :create), station: @create_attrs)

      assert ["Bearer #{token}"] == get_req_header(conn, "authorization")

      assert json_response(conn, 401) == %{
               "errors" => %{"detail" => "Invalid scopes for resource."}
             }
    end

    @tag :authenticated
    test "renders station when data is valid", %{conn: conn} do
      conn = post(conn, station_path(conn, :create), station: @create_attrs)
      assert %{"id" => id, "slug" => "some-name" = slug} = json_response(conn, 201)

      conn = get(conn, station_path(conn, :show, slug))

      assert json_response(conn, 200) == %{
               "slug" => slug,
               "id" => id,
               "name" => "some name",
               "play_type" => "public",
               "tags" => [],
               "current_track" => nil,
               "guests" => 0,
               "users" => [],
               "queue" => []
             }
    end

    @tag :authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, station_path(conn, :create), station: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end
end
