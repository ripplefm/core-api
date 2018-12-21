defmodule Ripple.Stations.StationEventListener do
  use GenServer
  import Ecto.Query

  alias Ripple.Tracks.Track

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: :station_event_listener)
  end

  def init(_) do
    EventBus.subscribe(
      {__MODULE__, ["station_track_started", "station_track_finished", "station_stopped"]}
    )

    {:ok, :ok}
  end

  def process({topic, id} = e) do
    try do
      event = EventBus.fetch_event(e)
      process(topic, event.data)
      EventBus.mark_as_completed({__MODULE__, topic, id})
    rescue
      _ -> nil
    catch
      :exit, _ -> nil
      _ -> nil
    end
  end

  def process(:station_track_started, %{station: station, target: %Track{} = track}) do
    Ripple.Stations.add_track_to_history(station.id, track.dj.id, track.id)
  end

  def process(:station_track_finished, %{station: station}) do
    Ripple.Stations.mark_track_as_finished(station.id)
  end

  def process(:station_stopped, %{station: station}) do
    Ripple.Repo.transaction(fn ->
      from(t in Ripple.Stations.StationTrackHistory,
        where: t.station_id == ^station.id,
        where: is_nil(t.finished_at)
      )
      |> Ripple.Repo.update_all(set: [finished_at: DateTime.utc_now()])
    end)
  end
end
