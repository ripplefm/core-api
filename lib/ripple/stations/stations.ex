defmodule Ripple.Stations do
  import Ecto.Query, warn: false
  alias Ripple.Repo

  alias Ripple.Stations.{Station, StationStore, StationTrackHistory}

  def list_stations do
    StationStore.list_stations()
  end

  def get_station!(slug) do
    case StationStore.read(slug) do
      {:ok, nil} -> Repo.get_by!(Station, slug: slug)
      {:ok, station} -> station
      _ -> Repo.get_by!(Station, slug: slug)
    end
  end

  def get_station(slug) do
    try do
      get_station!(slug)
    rescue
      _ in Ecto.NoResultsError -> {:error, :not_found}
    end
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
      {:error, err} -> {:error, err}
      station -> {:ok, get_history_for(station, last_timestamp)}
    end
  end

  defp get_history_for(station, nil) do
    StationTrackHistory.for_station(station.id) |> Repo.all()
  end

  defp get_history_for(station, last_timestamp) do
    StationTrackHistory.for_station(station.id)
    |> StationTrackHistory.older_than(last_timestamp)
    |> Repo.all()
  end
end
