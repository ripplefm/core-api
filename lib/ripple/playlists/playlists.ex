defmodule Ripple.Playlists do
  @moduledoc """
  The Playlists context.
  """

  import Ecto.Query, warn: false
  alias Ripple.Repo

  alias Ripple.Tracks
  alias Ripple.Playlists.{Playlist, PlaylistTrack}

  @doc """
  Returns the list of playlists.

  ## Examples

      iex> list_playlists()
      [%Playlist{}, ...]

  """
  def list_playlists do
    Repo.all(Playlist)
  end

  @doc """
  Gets a single playlist.

  Raises `Ecto.NoResultsError` if the Playlist does not exist.

  ## Examples

      iex> get_playlist!(123)
      %Playlist{}

      iex> get_playlist!(456)
      ** (Ecto.NoResultsError)

  """
  def get_playlist!(slug) do
    Repo.get_by!(Playlist, slug: slug) |> Repo.preload([:tracks, :creator])
  end

  @doc """
  Creates a playlist.

  ## Examples

      iex> create_playlist(%{field: value})
      {:ok, %Playlist{}}

      iex> create_playlist(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_playlist(attrs \\ %{}) do
    %Playlist{}
    |> Playlist.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking playlist changes.

  ## Examples

      iex> change_playlist(playlist)
      %Ecto.Changeset{source: %Playlist{}}

  """
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
end
