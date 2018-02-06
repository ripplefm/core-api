defmodule Ripple.Stations.StationServer do
  use GenServer

  alias Ripple.Tracks
  alias Ripple.Stations.Station
  alias Ripple.Users.User

  # Client
  def start(station, user) do
    GenServer.start(__MODULE__, {station, user}, name: String.to_atom("stations:#{station.slug}"))
  end

  def add_user(slug, user) do
    GenServer.call(String.to_atom("stations:#{slug}"), {:add_user, user})
  end

  def remove_user(slug, user) do
    GenServer.call(String.to_atom("stations:#{slug}"), {:remove_user, user})
  end

  def add_track(slug, track_url, user) do
    GenServer.cast(String.to_atom("stations:#{slug}"), {:add_track, track_url, user})
  end

  # Server
  def init({%Station{} = station, nil}) do
    new_station = Map.put(station, :users, []) |> Map.put(:guests, 1)
    emit_event(:station_started, %{station: new_station, target: new_station})
    {:ok, new_station}
  end

  def init({%Station{} = station, %User{} = user}) do
    new_station = Map.put(station, :users, [user]) |> Map.put(:queue, [])
    emit_event(:station_started, %{station: new_station, target: new_station})
    {:ok, new_station}
  end

  def handle_call({:remove_user, nil}, _, state) do
    new_state = Map.put(state, :guests, Map.get(state, :guests, 1) - 1)
    user_count = Enum.count(new_state.users) + new_state.guests == 0
    emit_event(:station_user_left, %{station: new_state, target: "guest"})

    if user_count == 0 do
      GenServer.cast(self(), :stop)
    end

    {:reply, user_count == 0, new_state}
  end

  def handle_call({:remove_user, %User{} = user}, _, state) do
    users = Enum.filter(Map.get(state, :users, []), fn u -> u.id != user.id end)
    new_state = Map.put(state, :users, users)
    user_count = Enum.count(new_state.users) + new_state.guests == 0
    emit_event(:station_user_left, %{station: new_state, target: user})

    if user_count == 0 do
      GenServer.cast(self(), :stop)
    end

    {:reply, user_count == 0, new_state}
  end

  def handle_call({:add_user, nil}, _, state) do
    new_state = Map.put(state, :guests, Map.get(state, :guests, 0) + 1)
    emit_event(:station_user_joined, %{station: new_state, target: "guest"})
    {:reply, :ok, new_state}
  end

  def handle_call({:add_user, %User{} = user}, _, state) do
    users = Enum.filter(Map.get(state, :users, []), fn u -> u.id != user.id end)
    new_state = Map.put(state, :users, users ++ [user])

    emit_event(:station_user_joined, %{station: new_state, target: user})
    {:reply, :ok, new_state}
  end

  def handle_cast(:stop, state) do
    emit_event(:station_stopped, %{station: state, target: state})
    {:stop, :shutdown, state}
  end

  def handle_cast({:add_track, track_url, %User{} = user}, state) do
    track = Tracks.get_or_create_track(track_url) |> Map.put(:dj, user)

    case Map.fetch(state, :current_track) do
      {:ok, nil} ->
        Map.put(state, :current_track, track) |> start_track

      {:ok, _} ->
        add_track_to_queue(state, track)

      :error ->
        Map.put(state, :current_track, track) |> start_track
    end
  end

  def handle_info(:track_finished, state) do
    emit_event(:station_track_finished, %{
      station: Map.put(state, :current_track, nil),
      target: state
    })

    case Map.fetch(state, :queue) do
      {:ok, []} ->
        {:noreply, Map.put(state, :current_track, nil)}

      {:ok, [next | queue]} ->
        Map.put(state, :queue, queue) |> Map.put(:current_track, next)
        |> start_track

      :error ->
        {:noreply, state}
    end
  end

  defp add_track_to_queue(state, track) do
    new_state = Map.put(state, :queue, Map.get(state, :queue, []) ++ [track])
    emit_event(:station_queue_track_added, %{station: new_state, target: track})
    {:noreply, new_state}
  end

  defp start_track(state) do
    new_state =
      Map.put(
        state,
        :current_track,
        Map.put(state.current_track, :timestamp, :os.system_time(:millisecond))
      )

    emit_event(:station_track_started, %{station: new_state, target: new_state.current_track})
    Process.send_after(self(), :track_finished, new_state.current_track.duration)

    {:noreply, new_state}
  end

  defp emit_event(topic, state) do
    EventBus.notify(%EventBus.Model.Event{
      id: Ecto.UUID.generate(),
      topic: topic,
      data: state
    })
  end
end
