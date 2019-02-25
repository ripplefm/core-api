defmodule Ripple.AutoPlayers.AutoPlayerServer do
  use GenServer

  alias Ripple.Stations.StationServer

  def child_spec({station, user}) do
    %{
      id: "stations:#{station.slug}:autoplayer",
      start: {GenServer, :start_link, [__MODULE__, {station, user}]}
    }
  end

  def start(station, user) do
    Horde.Supervisor.start_child(Ripple.StationAutoPlayerSupervisor, child_spec({station, user}))
  end

  def init(state) do
    handle_info(:pick_track, state)
    {:ok, state}
  end

  def handle_info(:pick_track, {station, user} = state) do
    %{play_sources: sources} = Ripple.AutoPlayers.get_config_for_station(station)
    next_url = Ripple.AutoPlayers.PlaySourceResolver.get_next_url(sources)

    queue_state = Ripple.Stations.get_station(station.slug)
    users_in_queue = Enum.map(queue_state.queue, fn t -> t.dj.username end)

    unless user.username in users_in_queue do
      StationServer.add_track(station.slug, next_url, user)
      Process.sleep(1_000)
    end

    current_state = Ripple.Stations.get_station(station.slug)
    sleep_duration = max(current_state.current_track.duration - 2_000, 0)
    Process.send_after(self(), :pick_track, sleep_duration)
    {:noreply, state}
  end
end
