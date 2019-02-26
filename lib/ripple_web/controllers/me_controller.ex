defmodule RippleWeb.MeController do
  use RippleWeb, :controller

  alias Ripple.Stations
  alias Ripple.Stations.Station

  import RippleWeb.Helpers.AuthHelper

  action_fallback(RippleWeb.FallbackController)
  plug(:require_current_user)

  plug(:authorize_resource,
    model: Station,
    non_id_actions: [:show_created_stations, :show_following_stations]
  )

  def show_created_stations(conn, _params) do
    current_user = conn.assigns.current_user
    stations = Stations.get_stations_created_by(current_user)
    conn |> put_status(:ok) |> render(RippleWeb.StationView, "index.json", stations: stations)
  end

  def show_following_stations(conn, _params) do
    current_user = conn.assigns.current_user
    stations = Stations.get_stations_followed_by(current_user)
    conn |> put_status(:ok) |> render(RippleWeb.StationView, "index.json", stations: stations)
  end
end
