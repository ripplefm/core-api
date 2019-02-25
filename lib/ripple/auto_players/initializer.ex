defmodule Ripple.AutoPlayers.Initializer do
  alias Ripple.Stations
  alias Ripple.Stations.StationServer
  alias Ripple.AutoPlayers.AutoPlayerServer

  def start_auto_player_stations do
    user = Ripple.Users.get_user("autoplayer")

    unless user == {:error, :not_found} do
      stations = Stations.get_stations_created_by(user)

      # Ensure stations started
      stations
      |> Enum.filter(&(StationServer.is_running?(&1.slug) == false))
      |> Enum.each(&StationServer.start(&1, user))

      # Ensure auto players started
      stations |> Enum.each(&AutoPlayerServer.start(&1, user))
    end
  end
end
