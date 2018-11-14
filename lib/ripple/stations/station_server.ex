defmodule Ripple.Stations.StationServer do
  use GenServer

  alias Ripple.Tracks
  alias Ripple.Tracks.Track
  alias Ripple.Stations.{Station, LiveStation}
  alias Ripple.Users.User

  # Client
  def child_spec(%{station: station, user: user}) do
    %{
      id: "stations:#{station.slug}",
      start:
        {GenServer, :start_link, [__MODULE__, {station, user}, [name: via_tuple(station.slug)]]}
    }
  end

  def start(station, user) do
    Horde.Supervisor.start_child(
      Ripple.StationSupervisor,
      child_spec(%{station: station, user: user})
    )
  end

  def add_user(slug, user) do
    GenServer.call(via_tuple(slug), {:add_user, user})
  end

  def remove_user(slug, user) do
    GenServer.call(via_tuple(slug), {:remove_user, user})
  end

  def add_track(slug, track_url, user) do
    GenServer.cast(via_tuple(slug), {:add_track, track_url, user})
  end

  def get(slug), do: GenServer.call(via_tuple(slug), :get)

  def init({%Station{} = station, nil}) do
    Process.flag(:trap_exit, true)

    new_station = get_base_state(station, nil)

    emit_event(:station_started, %{station: new_station, target: new_station})
    {:ok, new_station}
  end

  def init({%Station{} = station, %User{} = user}) do
    Process.flag(:trap_exit, true)

    new_station = get_base_state(station, user)

    emit_event(:station_started, %{station: new_station, target: new_station})
    {:ok, new_station}
  end

  def handle_call(:get, _, state), do: {:reply, state, state}

  def handle_call({:remove_user, nil}, _, %LiveStation{guests: 1, users: []} = state) do
    new_state = %LiveStation{state | guests: 0}
    emit_event(:station_user_left, %{station: new_state, target: "guest"})
    GenServer.cast(self(), :stop)
    {:reply, true, new_state}
  end

  def handle_call({:remove_user, nil}, _, %LiveStation{guests: guests} = state) do
    new_state = %LiveStation{state | guests: guests - 1}
    emit_event(:station_user_left, %{station: new_state, target: "guest"})
    {:reply, false, new_state}
  end

  def handle_call(
        {:remove_user, %User{} = user},
        _,
        %LiveStation{users: [user], guests: 0} = state
      ) do
    new_state = %LiveStation{state | users: []}
    emit_event(:station_user_left, %{station: new_state, target: user})
    GenServer.cast(self(), :stop)
    {:reply, true, new_state}
  end

  def handle_call({:remove_user, %User{} = user}, _, %LiveStation{users: users} = state) do
    new_state = %LiveStation{state | users: List.delete(users, user)}
    emit_event(:station_user_left, %{station: new_state, target: user})
    {:reply, false, new_state}
  end

  def handle_call({:add_user, nil}, _, %LiveStation{guests: guests} = state) do
    new_state = %LiveStation{state | guests: guests + 1}
    emit_event(:station_user_joined, %{station: new_state, target: "guest"})
    {:reply, :ok, new_state}
  end

  def handle_call({:add_user, %User{} = user}, _, %LiveStation{users: users} = state) do
    filtered_users = Enum.filter(users, fn u -> u.id != user.id end)
    new_state = %LiveStation{state | users: filtered_users ++ [user]}
    emit_event(:station_user_joined, %{station: new_state, target: user})
    {:reply, :ok, new_state}
  end

  def handle_cast(
        {:add_track, track_url, %User{} = user},
        %LiveStation{play_type: "private", current_track: nil} = state
      ) do
    if user.id == state.creator_id do
      track = Tracks.get_or_create_track(track_url) |> Map.put(:dj, user)
      %LiveStation{state | current_track: track} |> start_track
    else
      {:reply, {:error, :not_creator}, state}
    end
  end

  def handle_cast(
        {:add_track, track_url, %User{} = user},
        %LiveStation{play_type: "private"} = state
      ) do
    if user.id == state.creator_id do
      track = Tracks.get_or_create_track(track_url) |> Map.put(:dj, user)
      add_track_to_queue(state, track)
    else
      {:reply, {:error, :not_creator}, state}
    end
  end

  def handle_cast(
        {:add_track, track_url, %User{} = user},
        %LiveStation{current_track: nil, users: users} = state
      ) do
    if user in users do
      track = Tracks.get_or_create_track(track_url) |> Map.put(:dj, user)
      %LiveStation{state | current_track: track} |> start_track
    else
      {:reply, {:error, :not_in_station}, state}
    end
  end

  def handle_cast({:add_track, track_url, %User{} = user}, %LiveStation{users: users} = state) do
    if user in users do
      track = Tracks.get_or_create_track(track_url) |> Map.put(:dj, user)
      add_track_to_queue(state, track)
    else
      {:reply, {:error, :not_in_station}, state}
    end
  end

  def handle_cast(:stop, %LiveStation{slug: slug} = state) do
    emit_event(:station_stopped, %{station: state, target: state})
    Horde.Supervisor.terminate_child(Ripple.StationSupervisor, "stations:#{slug}")
  end

  def handle_info(:track_finished, %LiveStation{queue: []} = state) do
    new_state = %LiveStation{state | current_track: nil}
    emit_event(:station_track_finished, %{station: new_state, target: new_state})
    {:noreply, new_state}
  end

  def handle_info(:track_finished, %LiveStation{queue: [next | queue]} = state) do
    new_state = %LiveStation{state | current_track: next, queue: queue}
    emit_event(:station_track_finished, %{station: new_state, target: new_state})
    new_state |> start_track
  end

  def handle_info({:EXIT, _pid, reason}, %LiveStation{} = state) do
    {:stop, reason, state}
  end

  def handle_info({:stop_if_empty, %LiveStation{users: [], guests: 0} = state}) do
    GenServer.cast(self(), :stop)
    {:noreply, state}
  end

  def handle_info({:stop_if_empty, %LiveStation{} = state}) do
    {:noreply, state}
  end

  def via_tuple(slug) do
    {:via, Horde.Registry, {Ripple.StationRegistry, "stations:#{slug}"}}
  end

  defp get_base_state(%Station{} = station, nil) do
    creator = Map.get(station, :creator, nil)
    creator_id = if creator == nil, do: station.creator_id, else: creator.id

    %LiveStation{
      id: station.id,
      name: station.name,
      play_type: station.play_type,
      slug: station.slug,
      creator_id: creator_id,
      guests: 1,
      users: [],
      current_track: nil,
      queue: []
    }
  end

  defp get_base_state(%Station{} = station, %User{} = user) do
    creator = Map.get(station, :creator, nil)
    creator_id = if creator == nil, do: station.creator_id, else: creator.id

    %LiveStation{
      id: station.id,
      name: station.name,
      play_type: station.play_type,
      slug: station.slug,
      creator_id: creator_id,
      guests: 0,
      users: [user],
      current_track: nil,
      queue: []
    }
  end

  defp add_track_to_queue(%LiveStation{queue: queue} = station, %Track{} = track) do
    new_state = %LiveStation{station | queue: queue ++ [track]}
    emit_event(:station_queue_track_added, %{station: new_state, target: track})
    {:noreply, new_state}
  end

  defp start_track(%LiveStation{current_track: track} = state) do
    timestamped_track = Map.put(track, :timestamp, :os.system_time(:millisecond))
    new_state = %LiveStation{state | current_track: timestamped_track}
    emit_event(:station_track_started, %{station: new_state, target: timestamped_track})

    Process.send_after(self(), :track_finished, timestamped_track.duration)

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
