defmodule RippleWeb.StationController do
  use RippleWeb, :controller

  alias Ripple.Stations
  alias Ripple.Stations.Station

  import RippleWeb.Helpers.AuthHelper

  action_fallback(RippleWeb.FallbackController)
  plug(:require_current_user when action in [:create])
  plug(:authorize_resource, model: Station, only: :create)

  def index(conn, _params) do
    stations = Stations.list_stations()
    render(conn, "index.json", stations: stations)
  end

  def create(conn, %{"station" => station_params}) do
    with {:ok, %Station{} = station} <-
           Stations.create_station(
             Map.put(station_params, "creator_id", conn.assigns.current_user.id)
           ) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", station_path(conn, :show, station))
      |> render("show.json", station: station)
    end
  end

  def show(conn, %{"slug" => slug}) do
    station = Stations.get_station!(slug)
    render(conn, "show.json", station: station)
  end
end
