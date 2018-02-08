defmodule Ripple.Tracks do
  @moduledoc """
  The Tracks context.
  """

  import Ecto.Query, warn: false
  alias Ripple.Repo

  alias Ripple.Tracks.Track
  alias Ripple.Tracks.Providers.{YouTube, SoundCloud}

  @doc """
  Returns the list of tracks.

  ## Examples

      iex> list_tracks()
      [%Track{}, ...]

  """
  def list_tracks do
    Repo.all(Track)
  end

  @doc """
  Gets a single track.

  Raises `Ecto.NoResultsError` if the Track does not exist.

  ## Examples

      iex> get_track!(123)
      %Track{}

      iex> get_track!(456)
      ** (Ecto.NoResultsError)

  """
  def get_track!(id), do: Repo.get!(Track, id)

  @doc """
  Creates a track.

  ## Examples

      iex> create_track(%{field: value})
      {:ok, %Track{}}

      iex> create_track(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_track(url) do
    attrs =
      case URI.parse(url) do
        %{host: "www.youtube.com"} -> YouTube.get_track(url)
        %{host: "soundcloud.com"} -> SoundCloud.get_track(url)
        _ -> raise ArgumentError, message: "Invalid track provider url"
      end

    %Track{}
    |> Track.changeset(attrs)
    |> Repo.insert()
    |> elem(1)
  end

  # def create_track(attrs \\ %{}) do
  #   %Track{}
  #   |> Track.changeset(attrs)
  #   |> Repo.insert()
  # end

  @doc """
  Updates a track.

  ## Examples

      iex> update_track(track, %{field: new_value})
      {:ok, %Track{}}

      iex> update_track(track, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_track(%Track{} = track, attrs) do
    track
    |> Track.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Track.

  ## Examples

      iex> delete_track(track)
      {:ok, %Track{}}

      iex> delete_track(track)
      {:error, %Ecto.Changeset{}}

  """
  def delete_track(%Track{} = track) do
    Repo.delete(track)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking track changes.

  ## Examples

      iex> change_track(track)
      %Ecto.Changeset{source: %Track{}}

  """
  def change_track(%Track{} = track) do
    Track.changeset(track, %{})
  end

  def get_or_create_track(url) do
    track = Repo.get_by(Track, url: url)

    case track do
      nil -> create_track(url)
      _ -> track
    end
  end
end
