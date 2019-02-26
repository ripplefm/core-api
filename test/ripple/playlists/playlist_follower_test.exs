defmodule Ripple.PlaylistFollowerTest do
  use Ripple.DataCase

  alias Ripple.Playlists
  alias Ripple.Playlists.PlaylistFollower

  describe "Playlist Followers" do
    setup do
      {:ok, user} = Ripple.Users.upsert_user(%{username: "tester"})

      {:ok, playlist} =
        Playlists.create_playlist(%{
          creator_id: user.id,
          name: "my playlist",
          tags: [],
          visibility: "public"
        })

      %{user: user, playlist: playlist}
    end

    test "follow_playlist/2 successfully follows a playlist", %{playlist: playlist, user: user} do
      {:ok, %PlaylistFollower{} = f} = Playlists.follow_playlist(playlist, user)

      assert f.user_id == user.id
      assert f.playlist_id == playlist.id

      {:ok, p} = Playlists.get_playlist_for_user(playlist.slug, user)
      assert p.followers == 1
    end

    test "follow_playlist/2 returns error when already following", %{
      playlist: playlist,
      user: user
    } do
      {:ok, %PlaylistFollower{}} = Playlists.follow_playlist(playlist, user)
      assert {:error, :already_following} == Playlists.follow_playlist(playlist, user)

      {:ok, p} = Playlists.get_playlist_for_user(playlist.slug, user)
      assert p.followers == 1
    end

    test "follow_playlist/2 returns error when playlist is private", %{user: user} do
      {:ok, other_user} = Ripple.Users.create_user(%{username: "other_user"})

      {:ok, p} =
        Playlists.create_playlist(%{
          creator_id: user.id,
          visibility: "private",
          tags: [],
          name: "private"
        })

      playlist = Playlists.get_playlist!(p.slug)
      assert {:error, :not_found} = Playlists.follow_playlist(playlist, other_user)

      {:ok, p} = Playlists.get_playlist_for_user(playlist.slug, user)
      assert p.followers == 0
    end

    test "unfollow_playlist/2 successfully unfollows a playlist", %{
      playlist: playlist,
      user: user
    } do
      {:ok, %PlaylistFollower{}} = Playlists.follow_playlist(playlist, user)

      {:ok, p} = Playlists.get_playlist_for_user(playlist.slug, user)
      assert p.followers == 1

      :ok = Playlists.unfollow_playlist(playlist, user)

      {:ok, p} = Playlists.get_playlist_for_user(playlist.slug, user)
      assert p.followers == 0
    end

    test "unfollow_playlist/2 returns error when not following playlist", %{
      playlist: playlist,
      user: user
    } do
      assert {:error, :not_following} == Playlists.unfollow_playlist(playlist, user)

      {:ok, p} = Playlists.get_playlist_for_user(playlist.slug, user)
      assert p.followers == 0
    end
  end
end
