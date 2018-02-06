defmodule Ripple.Stations.StationRegistry do
  use GenServer

  alias Ripple.Stations.Station

  # Client
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: :station_registry)
  end

  def update(%Station{} = station), do: GenServer.cast(:station_registry, {:update, station})

  def remove(%Station{} = station), do: GenServer.cast(:station_registry, {:remove, station})

  def get_by_slug(slug), do: GenServer.call(:station_registry, {:get_by_slug, slug})

  def get_stations(s, e), do: GenServer.call(:station_registry, {:slice, s, e})

  def get_stations, do: GenServer.call(:station_registry, :slice)

  # Server
  def init(_) do
    EventBus.subscribe({__MODULE__, ["station_*"]})
    {:ok, [{:stations, %{}}, {:cache, []}]}
  end

  def process({:station_stopped, id} = e) do
    event = EventBus.fetch_event(e)
    remove(event.data.station)
    EventBus.mark_as_completed({__MODULE__, :station_stopped, id})
  end

  def process({topic, id} = e) do
    event = EventBus.fetch_event(e)
    update(event.data.station)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def handle_cast({:update, %Station{} = station}, state) do
    # Ensure station has a users array
    new_station = Map.put(station, :users, Map.get(station, :users, []))
    stations = Map.put(state[:stations], new_station.slug, new_station)
    {:noreply, [{:stations, stations}, {:cache, generate_cache(stations)}]}
  end

  def handle_cast({:remove, %Station{} = station}, state) do
    stations = Map.delete(state[:stations], station.slug)
    {:noreply, [{:stations, stations}, {:cache, generate_cache(stations)}]}
  end

  def handle_call({:get_by_slug, slug}, _, state), do: {:reply, state[:stations][slug], state}

  def handle_call(:slice, _, state), do: {:reply, Enum.slice(state[:cache], 0, 10), state}

  def handle_call({:slice, s, e}, _, state), do: {:reply, Enum.slice(state[:cache], s, e), state}

  defp generate_cache(stations) do
    # TODO: cache should only have stations with "public" play_type
    # TODO: (maybe) cache should aggregate arrays such as queue/users to be count instead of full array
    # TODO: look into moving cache to :ets or mnesia
    stations
    |> Enum.sort(&sort/2)
    |> Enum.map(&(&1 |> elem(1)))
  end

  defp sort({_, %{users: u1, guests: g1}}, {_, %{users: u2, guests: g2}}),
    do: Enum.count(u1) + g1 >= Enum.count(u2) + g2
end
