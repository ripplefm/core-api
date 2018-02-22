defmodule RippleWeb.PlaylistControllerTest do
  use RippleWeb.ConnCase

  alias Ripple.Playlists

  @create_attrs %{name: "some playlist", visibility: "public"}
  @private_attrs %{name: "private playlist", visibility: "private"}
  @invalid_attrs %{name: nil, visibility: nil}
  @track_url "https://www.youtube.com/watch?v=4Rc-NGWEHdU"

  def fixture do
    {:ok, user} = Ripple.Users.create_user(%{username: "tester"})
    {:ok, playlist} = Playlists.create_playlist(@create_attrs |> Map.put(:creator_id, user.id))
    playlist
  end

  def token_fixture do
    %{
      scopes: ["user:read", "playlists:read"],
      user: %{id: Ecto.UUID.generate(), username: "tester"}
    }
    |> RippleWeb.Helpers.JWTHelper.sign()
  end

  def token_fixture(%{scopes: scopes}) do
    %{
      scopes: scopes,
      user: %{id: Ecto.UUID.generate(), username: "tester"}
    }
    |> RippleWeb.Helpers.JWTHelper.sign()
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create" do
    @tag :authenticated
    test "creates a valid playlist", %{conn: conn} do
      conn = post(conn, playlist_path(conn, :create), playlist: @create_attrs)

      assert json_response(conn, 201) == %{
               "creator" => %{
                 "id" => conn.assigns.current_user.id,
                 "username" => conn.assigns.current_user.username
               },
               "name" => "some playlist",
               "slug" => "some-playlist",
               "visibility" => "public",
               "tracks" => []
             }
    end

    test "fails to create playlist for anonymous user", %{conn: conn} do
      conn = post(conn, playlist_path(conn, :create), playlist: @create_attrs)

      assert json_response(conn, 401) == %{
               "errors" => %{"detail" => "Missing or invalid token in Authorization header."}
             }
    end

    test "fails to create when missing 'playlists:write' scope", %{conn: conn} do
      token = token_fixture()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(playlist_path(conn, :create), playlist: @create_attrs)

      assert json_response(conn, 401) == %{
               "errors" => %{"detail" => "Invalid scopes for resource."}
             }
    end

    @tag :authenticated
    test "error for invalid params", %{conn: conn} do
      conn = post(conn, playlist_path(conn, :create), playlist: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "show" do
    test "renders a playlist when data is valid", %{conn: conn} do
      playlist = fixture()
      conn = get(conn, playlist_path(conn, :show, playlist.slug))
      assert json_response(conn, 200)["slug"] == playlist.slug
    end

    test "playlist with private visibility is hidden to random user", %{conn: conn} do
      {:ok, user} = Ripple.Users.create_user(%{username: "tester"})
      {:ok, playlist} = Playlists.create_playlist(@private_attrs |> Map.put(:creator_id, user.id))
      conn = get(conn, playlist_path(conn, :show, playlist.slug))
      assert json_response(conn, 404) == %{"errors" => %{"detail" => "Playlist not found"}}
    end

    @tag :authenticated
    test "playlist with private visibility visible to creator", %{conn: conn} do
      user = Ripple.Users.get_user!("tester")
      {:ok, playlist} = Playlists.create_playlist(@private_attrs |> Map.put(:creator_id, user.id))
      conn = get(conn, playlist_path(conn, :show, playlist.slug))
      assert json_response(conn, 200)["slug"] == playlist.slug
    end

    @tag :authenticated
    test "playlist that doesn't exist returns 404 as authenticated user", %{conn: conn} do
      conn = get(conn, playlist_path(conn, :show, "none"))
      assert json_response(conn, 404) == %{"errors" => %{"detail" => "Playlist not found"}}
    end

    test "playlist that doesn't exist returns 404 as anonymous user", %{conn: conn} do
      conn = get(conn, playlist_path(conn, :show, "none"))
      assert json_response(conn, 404) == %{"errors" => %{"detail" => "Playlist not found"}}
    end

    test "fail to access private playlist without at least 'playlist:read' scope", %{conn: conn} do
      token = token_fixture(%{scopes: ["user:read"]})
      {:ok, user} = Ripple.Users.upsert_user(%{username: "tester"})
      {:ok, playlist} = Playlists.create_playlist(@private_attrs |> Map.put(:creator_id, user.id))

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(playlist_path(conn, :show, playlist.slug))

      assert json_response(conn, 401) == %{
               "errors" => %{"detail" => "Invalid scopes for resource."}
             }
    end
  end

  describe "add" do
    @tag :authenticated
    test "add track to a valid playlist", %{conn: conn} do
      user = Ripple.Users.get_user!("tester")
      {:ok, playlist} = Playlists.create_playlist(@create_attrs |> Map.put(:creator_id, user.id))
      conn = post(conn, playlist_path(conn, :add, playlist.slug), track_url: @track_url)

      assert json_response(conn, 201)["url"] == @track_url
    end

    test "fails to add track to playlist as anonymous user", %{conn: conn} do
      playlist = fixture()
      conn = post(conn, playlist_path(conn, :add, playlist.slug), track_url: @track_url)

      assert json_response(conn, 401) == %{
               "errors" => %{"detail" => "Missing or invalid token in Authorization header."}
             }
    end

    test "fails to add track to playlist when missing 'playlists:write' scope", %{conn: conn} do
      token = token_fixture()
      playlist = fixture()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(playlist_path(conn, :add, playlist.slug), track_url: @track_url)

      assert json_response(conn, 401) == %{
               "errors" => %{"detail" => "Invalid scopes for resource."}
             }
    end

    @tag :authenticated
    test "fail to add track for public playlist owned by someone else", %{conn: conn} do
      {:ok, user} = Ripple.Users.upsert_user(%{username: "else"})
      {:ok, playlist} = Playlists.create_playlist(@create_attrs |> Map.put(:creator_id, user.id))

      conn = post(conn, playlist_path(conn, :add, playlist.slug), track_url: @track_url)

      assert json_response(conn, 403) == %{"errors" => %{"detail" => "Must be playlist creator"}}
    end

    @tag :authenticated
    test "add track to private playlist", %{conn: conn} do
      user = Ripple.Users.get_user!("tester")
      {:ok, playlist} = Playlists.create_playlist(@private_attrs |> Map.put(:creator_id, user.id))

      conn = post(conn, playlist_path(conn, :add, playlist.slug), track_url: @track_url)

      assert json_response(conn, 201)["url"] == @track_url
    end

    @tag :authenticated
    test "fail to add track for private playlist owned by someone else", %{conn: conn} do
      {:ok, user} = Ripple.Users.upsert_user(%{username: "else"})
      {:ok, playlist} = Playlists.create_playlist(@private_attrs |> Map.put(:creator_id, user.id))

      conn = post(conn, playlist_path(conn, :add, playlist.slug), track_url: @track_url)

      assert json_response(conn, 404) == %{"errors" => %{"detail" => "Playlist not found"}}
    end

    @tag :authenticated
    test "add track to non-existent playlist", %{conn: conn} do
      conn = post(conn, playlist_path(conn, :add, "nothing"), track_url: @track_url)

      assert json_response(conn, 404) == %{"errors" => %{"detail" => "Playlist not found"}}
    end

    @tag :authenticated
    test "add invalid track to playlist", %{conn: conn} do
      user = Ripple.Users.get_user!("tester")
      {:ok, playlist} = Playlists.create_playlist(@create_attrs |> Map.put(:creator_id, user.id))

      assert_raise ArgumentError, fn ->
        post(conn, playlist_path(conn, :add, playlist.slug), track_url: "")
      end
    end

    @tag :authenticated
    test "add duplicate track to playlist", %{conn: conn} do
      user = Ripple.Users.get_user!("tester")
      {:ok, playlist} = Playlists.create_playlist(@create_attrs |> Map.put(:creator_id, user.id))
      {:ok, _} = Playlists.add_track_to_playlist(user, playlist.slug, @track_url)

      assert_raise Ecto.ConstraintError, fn ->
        post(conn, playlist_path(conn, :add, playlist.slug), track_url: @track_url)
      end
    end
  end

  describe "remove" do
    @tag :authenticated
    test "remove a track from a public playlist", %{conn: conn} do
      user = Ripple.Users.get_user!("tester")
      {:ok, playlist} = Playlists.create_playlist(@create_attrs |> Map.put(:creator_id, user.id))
      {:ok, _} = Playlists.add_track_to_playlist(user, playlist.slug, @track_url)

      conn = delete(conn, playlist_path(conn, :remove, playlist.slug), track_url: @track_url)

      assert response(conn, 204) == ""
    end

    @tag :authenticated
    test "remove track for private playlist as creator", %{conn: conn} do
      user = Ripple.Users.get_user!("tester")
      {:ok, playlist} = Playlists.create_playlist(@private_attrs |> Map.put(:creator_id, user.id))
      {:ok, _} = Playlists.add_track_to_playlist(user, playlist.slug, @track_url)

      conn = delete(conn, playlist_path(conn, :remove, playlist.slug), track_url: @track_url)

      assert response(conn, 204) == ""
    end

    @tag :authenticated
    test "fails to remove a track from a non-existent playlist", %{conn: conn} do
      conn = delete(conn, playlist_path(conn, :remove, "nothing"), track_url: @track_url)

      assert json_response(conn, 404) == %{"errors" => %{"detail" => "Playlist not found"}}
    end

    @tag :authenticated
    test "fails to remove a track from playlist that doesn't have that track", %{conn: conn} do
      user = Ripple.Users.get_user!("tester")
      {:ok, playlist} = Playlists.create_playlist(@create_attrs |> Map.put(:creator_id, user.id))

      conn = delete(conn, playlist_path(conn, :remove, playlist.slug), track_url: @track_url)

      assert json_response(conn, 422) == %{"errors" => %{"detail" => "Track not in playlist"}}
    end

    test "fails to remove track when missing 'playlists:write' scope", %{conn: conn} do
      token = token_fixture(%{scopes: ["user:read", "playlists:read"]})
      {:ok, user} = Ripple.Users.upsert_user(%{username: "else"})
      {:ok, playlist} = Playlists.create_playlist(@private_attrs |> Map.put(:creator_id, user.id))
      {:ok, _} = Playlists.add_track_to_playlist(user, playlist.slug, @track_url)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(playlist_path(conn, :remove, playlist.slug), track_url: @track_url)

      assert json_response(conn, 401) == %{
               "errors" => %{"detail" => "Invalid scopes for resource."}
             }
    end

    test "fails to remove track as anonymous user", %{conn: conn} do
      {:ok, user} = Ripple.Users.upsert_user(%{username: "tester"})
      {:ok, playlist} = Playlists.create_playlist(@create_attrs |> Map.put(:creator_id, user.id))
      {:ok, _} = Playlists.add_track_to_playlist(user, playlist.slug, @track_url)

      conn = delete(conn, playlist_path(conn, :remove, playlist.slug), track_url: @track_url)

      assert json_response(conn, 401) == %{
               "errors" => %{"detail" => "Missing or invalid token in Authorization header."}
             }
    end

    @tag :authenticated
    test "fails to remove track if not playlist creator", %{conn: conn} do
      {:ok, user} = Ripple.Users.upsert_user(%{username: "else"})
      {:ok, playlist} = Playlists.create_playlist(@create_attrs |> Map.put(:creator_id, user.id))
      {:ok, _} = Playlists.add_track_to_playlist(user, playlist.slug, @track_url)

      conn = delete(conn, playlist_path(conn, :remove, playlist.slug), track_url: @track_url)

      assert json_response(conn, 403) == %{
               "errors" => %{"detail" => "Must be playlist creator"}
             }
    end

    @tag :authenticated
    test "fails to remove track for private playlist if not creator", %{conn: conn} do
      {:ok, user} = Ripple.Users.upsert_user(%{username: "else"})
      {:ok, playlist} = Playlists.create_playlist(@private_attrs |> Map.put(:creator_id, user.id))
      {:ok, _} = Playlists.add_track_to_playlist(user, playlist.slug, @track_url)

      conn = delete(conn, playlist_path(conn, :remove, playlist.slug), track_url: @track_url)

      assert json_response(conn, 404) == %{
               "errors" => %{"detail" => "Playlist not found"}
             }
    end
  end
end
