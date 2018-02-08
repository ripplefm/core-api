defmodule RippleWeb.AuthenticationPlugsTest do
  use RippleWeb.ConnCase

  @invalid_attrs %{name: "", playtype: "", tags: []}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "authorization header" do
    @tag :authenticated
    test "valid header", %{conn: conn} do
      conn = post(conn, station_path(conn, :create), station: @invalid_attrs)
      assert conn.status == 422
      assert conn.assigns.authorized
      assert conn.assigns.current_user.username == "tester"
      assert conn.assigns.changeset.valid? == false
    end

    test "invalid token in header", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "invalid")
        |> post(station_path(conn, :create), station: @invalid_attrs)

      assert conn.status == 401
      assert conn.assigns.current_user == nil
      assert conn.resp_body == "{\"error\":\"Missing or invalid token in Authorization header.\"}"
    end

    test "missing header", %{conn: conn} do
      conn = post(conn, station_path(conn, :create), station: @invalid_attrs)
      assert conn.status == 401
      assert conn.assigns.current_user == nil
      assert conn.resp_body == "{\"error\":\"Missing or invalid token in Authorization header.\"}"
    end
  end
end
