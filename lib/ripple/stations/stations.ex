defmodule Ripple.Stations do
  import Ecto.Query, warn: false
  alias Ripple.Repo

  alias Ripple.Stations.{
    Station,
    StationStore,
    StationTrackHistory,
    StationFollower,
    StationServer
  }

  alias Ripple.Users.User

  def list_stations do
    StationStore.list_stations()
  end

  def get_station!(slug) do
    case StationStore.read(slug) do
      {:ok, nil} -> Station.all_stations() |> Station.with_slug(slug) |> Repo.one!()
      {:ok, station} -> station
    end
  end

  def get_station(slug) do
    {:ok, get_station!(slug)}
  rescue
    _ in Ecto.NoResultsError -> {:error, :not_found}
  end

  def get_stations_created_by(%User{} = user) do
    Station.all_stations()
    |> Station.created_by(user.id)
    |> Repo.all()
    |> convert_to_live
  end

  def get_stations_followed_by(%User{} = user) do
    Station.all_stations() |> Station.followed_by(user.id) |> Repo.all() |> convert_to_live
  end

  def create_station(attrs \\ %{}) do
    %Station{}
    |> Station.changeset(attrs)
    |> Repo.insert()
  end

  def change_station(%Station{} = station) do
    Station.changeset(station, %{})
  end

  def add_track_to_history(station_id, user_id, track_id) do
    %StationTrackHistory{}
    |> StationTrackHistory.changeset(%{
      station_id: station_id,
      user_id: user_id,
      track_id: track_id
    })
    |> Repo.insert()
  end

  def mark_track_as_finished(station_id) do
    from(h in StationTrackHistory,
      where: h.station_id == ^station_id,
      where: is_nil(h.finished_at)
    )
    |> Repo.update_all(set: [finished_at: DateTime.utc_now()])
  end

  def get_history(slug, last_timestamp \\ nil) do
    case get_station(slug) do
      {:ok, station} -> {:ok, get_history_for(station, last_timestamp)}
      {:error, err} -> {:error, err}
    end
  end

  defp get_history_for(%{id: station_id}, nil) do
    StationTrackHistory.for_station(station_id) |> Repo.all()
  end

  defp get_history_for(%{id: station_id}, last_timestamp) do
    StationTrackHistory.for_station(station_id)
    |> StationTrackHistory.older_than(last_timestamp)
    |> Repo.all()
  end

  def follow_station(%{id: station_id, slug: slug}, %User{} = user) do
    with {:ok, %StationFollower{}} = follower <-
           StationFollower.build(station_id, user.id) |> Repo.insert() do
      if StationServer.is_running?(slug) do
        StationServer.increment_follower_count(slug, 1)
      end

      follower
    end
  rescue
    Ecto.ConstraintError -> {:error, :already_following}
    _ -> {:error, :not_found}
  end

  def unfollow_station(%{id: station_id, slug: slug}, %User{} = user) do
    with {1, nil} <- StationFollower.find(station_id, user.id) |> Repo.delete_all() do
      if StationServer.is_running?(slug) do
        StationServer.increment_follower_count(slug, -1)
      end

      :ok
    else
      {0, nil} -> {:error, :not_following}
      _ -> {:error, :not_found}
    end
  end

  def is_followed_by?(%{id: station_id}, %User{} = user) do
    case StationFollower.find(station_id, user.id) |> Repo.one() do
      %StationFollower{} -> true
      nil -> false
    end
  end

  defp convert_to_live(stations) do
    stations
    |> Enum.map(fn s ->
      case StationServer.is_running?(s.slug) do
        true -> StationServer.get(s.slug)
        false -> s
      end
    end)
  end
end
