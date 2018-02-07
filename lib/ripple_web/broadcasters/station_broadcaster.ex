# Listens to station events and broadcasts relevant data
# to users in that station
defmodule RippleWeb.Broadcasters.StationBroadcaster do
  use GenServer

  alias Ripple.Stations.StationRegistry
  alias Ripple.Users.User

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: :station_echo)
  end

  def init(_) do
    EventBus.subscribe({__MODULE__, ["station_*"]})
    {:ok, :ok}
  end

  def process({topic, id} = e) do
    event = EventBus.fetch_event(e)
    station = event.data.station
    slug = station.slug
    # broadcast this event to websockets
    unless StationRegistry.get_by_slug(slug) == nil do
      with {:ok, payload} <- broadcast_event(topic, event.data) do
        RippleWeb.Endpoint.broadcast("stations:#{slug}", Atom.to_string(topic), payload)
      end
    end

    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  defp broadcast_event(:station_user_joined, %{target: user}) do
    {:ok, %{user: user}}
  end

  defp broadcast_event(:station_user_left, %{target: user}) do
    {:ok, %{user: user}}
  end

  defp broadcast_event(:station_track_finished, _) do
    {:ok, %{current_track: nil}}
  end

  defp broadcast_event(:station_track_started, %{target: track}) do
    {:ok, %{current_track: track}}
  end

  defp broadcast_event(:station_queue_track_added, %{target: track}) do
    {:ok, %{track: track.dj}}
  end

  defp broadcast_event(_, _), do: nil
end
