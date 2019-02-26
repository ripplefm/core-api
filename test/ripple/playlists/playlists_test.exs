defmodule Ripple.PlaylistsTest do
  use Ripple.DataCase

  alias Ripple.Playlists

  describe "playlists" do
    @valid_attrs %{name: "some name", visibility: "public"}
    @invalid_attrs %{name: nil, slug: nil, visibility: nil}
    @track_url "https://www.youtube.com/watch?v=4Rc-NGWEHdU"

    setup do
      {:ok, user} = Ripple.Users.upsert_user(%{username: "tester"})
      {:ok, playlist} = Playlists.create_playlist(@valid_attrs |> Map.put(:creator_id, user.id))
      %{playlist: playlist, user: user}
    end

    def private_fixture do
      {:ok, user} = Ripple.Users.upsert_user(%{username: "private_tester"})

      {:ok, playlist} =
        Playlists.create_playlist(%{
          name: "private playlist",
          creator_id: user.id,
          visibility: "private"
        })

      Playlists.get_playlist!(playlist.slug)
    end

    test "list_playlists/0 returns all playlists", %{playlist: playlist} do
      assert Playlists.list_playlists() == [playlist]
    end

    test "get_playlist!/1 returns the playlist with given slug", %{playlist: playlist, user: user} do
      result = Playlists.get_playlist!(playlist.slug)
      assert result.tracks == []
      assert result.creator == user
      assert result.name == playlist.name
      assert result.slug == playlist.slug
      assert result.visibility == playlist.visibility
    end

    test "create_playlist/1 with valid data creates a playlist", %{playlist: playlist} do
      assert playlist.name == "some name"
      assert playlist.slug == "some-name"
      assert playlist.visibility == "public"
    end

    test "create_playlist/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Playlists.create_playlist(@invalid_attrs)
    end

    test "is_creator?/2 returns true when creator of playlist", %{
      user: user
    } do
      playlist = Playlists.get_playlist!("some-name")
      assert Playlists.is_creator?(playlist, user) == true
    end

    test "is_creator?/2 returns false when not creator of playlist" do
      {:ok, user} = Ripple.Users.upsert_user(%{username: "else"})
      playlist = Playlists.get_playlist!("some-name")

      assert Playlists.is_creator?(playlist, user) == false
    end

    test "visible_to_user?/2 returns true for public playlist as creator", %{
      playlist: playlist,
      user: user
    } do
      assert Playlists.visible_to_user?(playlist, user) == true
    end

    test "visible_to_user?/2 returns true for public playlist as nil user", %{playlist: playlist} do
      assert Playlists.visible_to_user?(playlist, nil) === true
    end

    test "visible_to_user?/2 returns true for public playlist as random user", %{
      playlist: playlist
    } do
      {:ok, user} = Ripple.Users.upsert_user(%{username: "else"})
      assert Playlists.visible_to_user?(playlist, user) == true
    end

    test "visible_to_user?/2 returns true for private playlist as creator" do
      playlist = private_fixture()
      user = Ripple.Users.get_user!("private_tester")

      assert Playlists.visible_to_user?(playlist, user) == true
    end

    test "visible_to_user?/2 returns false for private playlist as nil user" do
      playlist = private_fixture()
      assert Playlists.visible_to_user?(playlist, nil) == false
    end

    test "visible_to_user?/2 returns false for private playlist as random user" do
      {:ok, user} = Ripple.Users.upsert_user(%{username: "else"})
      playlist = private_fixture()
      assert Playlists.visible_to_user?(playlist, user) == false
    end

    test "get_playlist_for_user/2 returns error tuple for non-existent playlist", %{user: user} do
      assert {:error, :playlist_not_found} == Playlists.get_playlist_for_user("nothing", user)
    end

    test "get_playlist_for_user/2 returns public playlist for creator", %{
      playlist: playlist,
      user: user
    } do
      {:ok, playlist2} = Playlists.get_playlist_for_user(playlist.slug, user)
      assert playlist2.slug == playlist.slug
    end

    test "get_playlist_for_user/2 returns public playlist for nil user", %{playlist: playlist} do
      {:ok, playlist2} = Playlists.get_playlist_for_user(playlist.slug, nil)
      assert playlist2.slug == playlist.slug
    end

    test "get_playlist_for_user/2 returns public playlist for random user", %{playlist: playlist} do
      {:ok, user} = Ripple.Users.upsert_user(%{username: "else"})
      {:ok, playlist2} = Playlists.get_playlist_for_user(playlist.slug, user)
      assert playlist2.slug == playlist.slug
    end

    test "get_playlist_for_user/2 returns private playlist for creator" do
      playlist = private_fixture()
      user = Ripple.Users.get_user!("private_tester")
      {:ok, playlist2} = Playlists.get_playlist_for_user(playlist.slug, user)
      assert playlist2.slug == playlist.slug
      assert playlist2.visibility == "private"
    end

    test "get_playlist_for_user/2 returns error for private playlist for nil user" do
      playlist = private_fixture()
      assert Playlists.get_playlist_for_user(playlist.slug, nil) == {:error, :playlist_not_found}
    end

    test "get_playlist_for_user/2 returns error for private playlist for random user", %{
      user: user
    } do
      playlist = private_fixture()
      assert Playlists.get_playlist_for_user(playlist.slug, user) == {:error, :playlist_not_found}
    end

    test "add_track_to_playlist/3 adds a track into an empty playlist", %{
      user: user,
      playlist: playlist
    } do
      {:ok, _} = Playlists.add_track_to_playlist(user, playlist.slug, @track_url)
      updated = Playlists.get_playlist!(playlist.slug)
      assert updated.slug == playlist.slug
      assert Enum.count(updated.tracks) == 1
    end

    test "add_track_to_playlist/3 throws error when track in playlist", %{
      user: user,
      playlist: playlist
    } do
      {:ok, _} = Playlists.add_track_to_playlist(user, playlist.slug, @track_url)

      assert_raise Ecto.ConstraintError, fn ->
        Playlists.add_track_to_playlist(user, playlist.slug, @track_url)
      end
    end

    test "add_track_to_playlist/3 throws error when playlist doesn't exist", %{user: user} do
      assert_raise Ecto.NoResultsError, fn ->
        Playlists.add_track_to_playlist(user, "nothing", @track_url)
      end
    end

    test "add_track_to_playlist/3 throws error when track url is invalid", %{
      user: user,
      playlist: playlist
    } do
      assert_raise ArgumentError, fn ->
        Playlists.add_track_to_playlist(user, playlist.slug, "")
      end
    end

    test "add_track_to_playlist/3 adds to private playlist when user is creator" do
      playlist = private_fixture()
      user = Ripple.Users.get_user!("private_tester")
      {:ok, track} = Playlists.add_track_to_playlist(user, playlist.slug, @track_url)

      assert track.url == @track_url
    end

    test "add_track_to_playlist/3 returns not creator error when not public playlist creator", %{
      playlist: playlist
    } do
      {:ok, user} = Ripple.Users.upsert_user(%{username: "else"})

      assert Playlists.add_track_to_playlist(user, playlist.slug, @track_url) ==
               {:error, :not_playlist_creator}
    end

    test "add_track_to_playlist/3 returns not found error when not private playlist creator" do
      playlist = private_fixture()
      {:ok, user} = Ripple.Users.upsert_user(%{username: "else"})

      assert Playlists.add_track_to_playlist(user, playlist.slug, @track_url) ==
               {:error, :playlist_not_found}
    end

    test "remove_track_from_playlist/3 properly removes track from a playlist", %{
      user: user,
      playlist: playlist
    } do
      {:ok, _} = Playlists.add_track_to_playlist(user, playlist.slug, @track_url)
      {:ok, deleted_track} = Playlists.remove_track_from_playlist(user, playlist.slug, @track_url)
      assert deleted_track.url == @track_url
    end

    test "remove_track_from_playlist/3 returns error when track not in playlist", %{
      user: user,
      playlist: playlist
    } do
      assert Playlists.remove_track_from_playlist(user, playlist.slug, @track_url) ==
               {:error, :track_not_in_playlist}
    end

    test "remove_track_from_playlist/3 throws an error when playlist doesn't exist", %{user: user} do
      assert_raise Ecto.NoResultsError, fn ->
        Playlists.remove_track_from_playlist(user, "nothing", @track_url)
      end
    end

    test "remove_track_from_playlist/3 throws an error when track url is invalid", %{
      user: user,
      playlist: playlist
    } do
      assert_raise ArgumentError, fn ->
        Playlists.remove_track_from_playlist(user, playlist.slug, "")
      end
    end

    test "remove_track_from_playlist/3 removes from private playlist when user is creator" do
      playlist = private_fixture()
      user = Ripple.Users.get_user!("private_tester")
      {:ok, _} = Playlists.add_track_to_playlist(user, playlist.slug, @track_url)
      {:ok, track} = Playlists.remove_track_from_playlist(user, playlist.slug, @track_url)

      assert track.url === @track_url
    end

    test "remove_track_from_playlist/3 returns not in playlist error when user is creator and track not in playlist",
         %{user: user, playlist: playlist} do
      assert Playlists.remove_track_from_playlist(user, playlist.slug, @track_url) ==
               {:error, :track_not_in_playlist}
    end

    test "remove_track_from_playlist/3 returns not creator error when not public playlist creator",
         %{playlist: playlist} do
      {:ok, user} = Ripple.Users.upsert_user(%{username: "else"})

      assert Playlists.remove_track_from_playlist(user, playlist.slug, @track_url) ==
               {:error, :not_playlist_creator}
    end

    test "remove_track_from_playlist/3 return not found error when not private playlist creator" do
      playlist = private_fixture()
      {:ok, user} = Ripple.Users.upsert_user(%{username: "else"})

      assert Playlists.remove_track_from_playlist(user, playlist.slug, @track_url) ==
               {:error, :playlist_not_found}
    end

    test "change_playlist/1 returns a playlist changeset", %{playlist: playlist} do
      assert %Ecto.Changeset{} = Playlists.change_playlist(playlist)
    end

    test "get_playlists_created_by/1 returns playlists only created by the user", %{
      user: user
    } do
      private = private_fixture()

      results = Playlists.get_playlists_created_by(user)

      assert Enum.count(results) == 1
      assert private not in results
    end

    test "get_playlists_created_by/1 includes public and private playlists", %{
      user: user
    } do
      {:ok, _} =
        Playlists.create_playlist(%{
          creator_id: user.id,
          name: "private",
          tags: [],
          visibility: "private"
        })

      results = Playlists.get_playlists_created_by(user)

      assert Enum.count(results) == 2
    end

    test "get_playlists_followed_by/1 returns only playlists followed by the user", %{
      user: user,
      playlist: playlist
    } do
      {:ok, _} =
        Playlists.create_playlist(%{
          creator_id: user.id,
          name: "other",
          tags: [],
          visibility: "public"
        })

      {:ok, _} = Playlists.follow_playlist(playlist, user)

      results = Playlists.get_playlists_followed_by(user)
      assert Enum.count(results) == 1
    end
  end
end
