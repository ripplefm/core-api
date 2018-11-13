defmodule Ripple.Stations.StationStoreSync do
  use GenServer

  alias Ripple.Stations.{StationStore, StationServer}

  @sync_delay 4_000

  def child_spec(_opts \\ nil) do
    %{
      id: "station_store_sync",
      start: {GenServer, :start_link, [__MODULE__, [], [name: :station_store_sync]]}
    }
  end

  def start do
    Horde.Supervisor.start_child(
      Ripple.StationStoreSyncSupervisor,
      child_spec()
    )
  end

  def init(state) do
    Process.send_after(self(), :sync_store, @sync_delay)

    StationStore.init_store()

    {:ok, state}
  end

  def handle_info(:sync_store, state) do
    ensure_live_stations_in_store()

    Process.send_after(self(), :sync_store, @sync_delay)
    {:noreply, state}
  end

  defp ensure_live_stations_in_store() do
    # Check if supervisor has active children equal to store size
    station_processes = Horde.Supervisor.count_children(Ripple.StationSupervisor)
    num_station_processes = Map.get(station_processes, :active, 0)
    num_stored_stations = StationStore.num_stations()

    unless num_station_processes == num_stored_stations do
      stations =
        Horde.Supervisor.which_children(Ripple.StationSupervisor)
        |> Enum.map(&List.first(&1))
        |> Enum.map(&elem(&1, 0))
        |> Enum.map(&String.slice(&1, String.length("stations:")..String.length(&1)))
        |> Enum.map(&StationServer.get/1)

      StationStore.clear_and_save(stations)
    end
  end
end
