defmodule Ripple.Stations do
  import Ecto.Query, warn: false
  alias Ripple.Repo

  alias Ripple.Stations.{Station, StationStore, StationTrackHistory, StationFollower}
  alias Ripple.Users.User

  def list_stations do
    StationStore.list_stations()
  end

  def get_station!(slug) do
    case StationStore.read(slug) do
      {:ok, nil} -> Repo.one!(Station.find(slug))
      {:ok, station} -> station
      _ -> Repo.one!(Station.find(slug))
    end
  end

  def get_station(slug) do
    case slug |> Station.find() |> Repo.one() do
      nil -> {:error, :not_found}
      station -> {:ok, station}
    end
  end

  def get_stations_created_by(%User{} = user) do
    Station.all_stations()
    |> Station.with_public_visibility()
    |> Station.created_by(user.id)
    |> Repo.all()
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

  defp get_history_for(%Station{} = station, nil) do
    StationTrackHistory.for_station(station.id) |> Repo.all()
  end

  defp get_history_for(%Station{} = station, last_timestamp) do
    StationTrackHistory.for_station(station.id)
    |> StationTrackHistory.older_than(last_timestamp)
    |> Repo.all()
  end

  def follow_station(%Station{} = station, %User{} = user) do
    try do
      StationFollower.build(station.id, user.id) |> Repo.insert()
    rescue
      Ecto.ConstraintError -> {:error, :already_following}
      _ -> {:error, :not_found}
    end
  end

  def unfollow_station(%Station{} = station, %User{} = user) do
    result = StationFollower.find(station.id, user.id) |> Repo.delete_all()

    case result do
      {1, nil} -> :ok
      {0, nil} -> {:error, :not_following}
      _ -> {:error, :not_found}
    end
  end
end
