defmodule RippleWeb.PlaylistFollowerControllerTest do
  use RippleWeb.ConnCase

  alias Ripple.Playlists

  @create_attrs %{name: "some playlist", tags: [], visibility: "public"}

  def playlist_fixture do
    {:ok, user} = Ripple.Users.upsert_user(%{username: "test"})

    {:ok, playlist} =
      @create_attrs |> Map.put(:creator_id, user.id) |> Playlists.create_playlist()

    playlist
  end

  def token_fixture do
    %{
      scopes: ["user:read", "playlists:read"],
      user: %{id: Ecto.UUID.generate(), username: "tester"}
    }
    |> RippleWeb.Helpers.JWTHelper.sign()
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create" do
    test "401 when missing authorization header", %{conn: conn} do
      conn = post(conn, playlist_follower_path(conn, :create, "slug"))
      assert conn.status == 401
      assert conn.assigns.current_user == nil
    end

    test "401 when access token missing 'playlists:write' scope", %{conn: conn} do
      token = token_fixture()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(playlist_follower_path(conn, :create, "slug"))

      assert ["Bearer #{token}"] == get_req_header(conn, "authorization")

      assert json_response(conn, 401) == %{
               "errors" => %{"detail" => "Invalid scopes for resource."}
             }
    end

    @tag :authenticated
    test "201 when succesfully followed a playlist", %{conn: conn} do
      playlist = playlist_fixture()
      conn = post(conn, playlist_follower_path(conn, :create, playlist.slug))

      assert conn.status == 201
    end

    @tag :authenticated
    test "404 when trying to follow nonexistent playlist", %{conn: conn} do
      conn = post(conn, playlist_follower_path(conn, :create, "invalid"))

      assert json_response(conn, 404) == %{
               "errors" => %{"detail" => "Playlist not found"}
             }
    end

    @tag :authenticated
    test "422 when already following playlist", %{conn: conn} do
      playlist = playlist_fixture()
      user = Ripple.Users.get_user("tester")
      {:ok, _} = Playlists.follow_playlist(playlist, user)

      conn = post(conn, playlist_follower_path(conn, :create, playlist.slug))

      assert json_response(conn, 422) == %{
               "errors" => %{"detail" => "Already following resource"}
             }
    end
  end

  describe "delete" do
    test "401 when missing authorization header", %{conn: conn} do
      conn = delete(conn, playlist_follower_path(conn, :delete, "slug"))
      assert conn.status == 401
      assert conn.assigns.current_user == nil
    end

    test "401 when access token missing 'playlists:write' scope", %{conn: conn} do
      token = token_fixture()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(playlist_follower_path(conn, :delete, "slug"))

      assert ["Bearer #{token}"] == get_req_header(conn, "authorization")

      assert json_response(conn, 401) == %{
               "errors" => %{"detail" => "Invalid scopes for resource."}
             }
    end

    @tag :authenticated
    test "204 when successfully unfollowed a playlist", %{conn: conn} do
      playlist = playlist_fixture()
      user = Ripple.Users.get_user("tester")
      {:ok, _} = Playlists.follow_playlist(playlist, user)

      conn = delete(conn, playlist_follower_path(conn, :delete, playlist.slug))

      assert conn.status == 204
    end

    @tag :authenticated
    test "404 when trying to unfollow nonexistent playlist", %{conn: conn} do
      conn = delete(conn, playlist_follower_path(conn, :delete, "invalid"))

      assert json_response(conn, 404) == %{
               "errors" => %{"detail" => "Playlist not found"}
             }
    end

    @tag :authenticated
    test "422 when trying to unfollow playlist thats not followed", %{conn: conn} do
      playlist = playlist_fixture()
      conn = delete(conn, playlist_follower_path(conn, :delete, playlist.slug))

      assert json_response(conn, 422) == %{
               "errors" => %{"detail" => "Not following resource"}
             }
    end
  end
end
