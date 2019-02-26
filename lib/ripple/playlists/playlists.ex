defmodule Ripple.Playlists do
  @moduledoc """
  The Playlists context.
  """

  import Ecto.Query, warn: false
  alias Ripple.Repo

  alias Ripple.Tracks
  alias Ripple.Users.User
  alias Ripple.Playlists.{Playlist, PlaylistTrack, PlaylistFollower}

  def list_playlists do
    Repo.all(Playlist)
  end

  def get_playlist!(slug) do
    Playlist.all_playlists()
    |> Playlist.with_slug(slug)
    |> Repo.one!()
    |> Repo.preload([:tracks, :creator])
  end

  def get_playlists_created_by(%User{} = user) do
    Playlist.all_playlists()
    |> Playlist.created_by(user.id)
    |> Repo.all()
    |> Repo.preload(:tracks)
  end

  def get_playlists_followed_by(%User{} = user) do
    Playlist.all_playlists()
    |> Playlist.followed_by(user.id)
    |> Repo.all()
    |> Repo.preload(:tracks)
  end

  def create_playlist(attrs \\ %{}) do
    %Playlist{}
    |> Playlist.changeset(attrs)
    |> Repo.insert()
  end

  def change_playlist(%Playlist{} = playlist) do
    Playlist.changeset(playlist, %{})
  end

  def is_creator?(%Playlist{} = playlist, user),
    do: user != nil and playlist.creator.id == user.id

  def visible_to_user?(%Playlist{} = playlist, user),
    do: playlist.visibility == "public" or is_creator?(playlist, user)

  def get_playlist_for_user(slug, user) do
    playlist = get_playlist!(slug)

    if visible_to_user?(playlist, user) do
      {:ok, playlist}
    else
      {:error, :playlist_not_found}
    end
  rescue
    Ecto.NoResultsError -> {:error, :playlist_not_found}
  end

  def add_track_to_playlist(user, slug, track_url) do
    playlist = get_playlist!(slug)
    track = Tracks.get_or_create_track(track_url)

    cond do
      is_creator?(playlist, user) ->
        {:ok, %PlaylistTrack{}} =
          %PlaylistTrack{}
          |> PlaylistTrack.changeset(%{playlist_id: playlist.id, track_id: track.id})
          |> Repo.insert()

        {:ok, track}

      visible_to_user?(playlist, user) ->
        {:error, :not_playlist_creator}

      not visible_to_user?(playlist, user) ->
        {:error, :playlist_not_found}
    end
  end

  def remove_track_from_playlist(user, slug, track_url) do
    playlist = get_playlist!(slug)
    track = Tracks.get_or_create_track(track_url)

    query =
      from(
        pt in PlaylistTrack,
        where: pt.playlist_id == ^playlist.id and pt.track_id == ^track.id
      )

    cond do
      is_creator?(playlist, user) ->
        with {1, nil} <- Repo.delete_all(query) do
          {:ok, track}
        else
          {0, nil} -> {:error, :track_not_in_playlist}
          _ -> {:error, :unknown}
        end

      visible_to_user?(playlist, user) ->
        {:error, :not_playlist_creator}

      not visible_to_user?(playlist, user) ->
        {:error, :playlist_not_found}
    end
  end

  def follow_playlist(%Playlist{} = playlist, %User{} = user) do
    if playlist |> visible_to_user?(user) do
      PlaylistFollower.build(playlist.id, user.id) |> Repo.insert()
    else
      {:error, :not_found}
    end
  rescue
    Ecto.ConstraintError -> {:error, :already_following}
  end

  def unfollow_playlist(%Playlist{} = playlist, %User{} = user) do
    result = PlaylistFollower.find(playlist.id, user.id) |> Repo.delete_all()

    case result do
      {1, nil} -> :ok
      {0, nil} -> {:error, :not_following}
      _ -> {:error, :not_found}
    end
  end
end
