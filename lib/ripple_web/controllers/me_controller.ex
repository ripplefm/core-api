defmodule RippleWeb.MeController do
  use RippleWeb, :controller

  alias Ripple.Stations
  alias Ripple.Stations.Station
  alias Ripple.Playlists
  alias Ripple.Playlists.Playlist

  import RippleWeb.Helpers.AuthHelper

  action_fallback(RippleWeb.FallbackController)
  plug(:require_current_user)

  plug(:authorize_resource,
    model: Station,
    non_id_actions: [:show_created_stations, :show_following_stations, :get_is_following_station],
    only: [:show_created_stations, :show_following_stations, :get_is_following_station]
  )

  plug(:authorize_resource,
    model: Playlist,
    non_id_actions: [:show_created_playlists, :show_following_playlists],
    only: [:show_created_playlists, :show_following_playlists]
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

  def show_created_playlists(conn, _params) do
    current_user = conn.assigns.current_user
    playlists = Playlists.get_playlists_created_by(current_user)
    conn |> put_status(:ok) |> render(RippleWeb.PlaylistView, "many.json", playlists: playlists)
  end

  def show_following_playlists(conn, _params) do
    current_user = conn.assigns.current_user
    playlists = Playlists.get_playlists_followed_by(current_user)
    conn |> put_status(:ok) |> render(RippleWeb.PlaylistView, "many.json", playlists: playlists)
  end

  def get_is_following_station(conn, %{"slug" => slug}) do
    current_user = conn.assigns.current_user

    with {:ok, station} <- Stations.get_station(slug),
         result <- Stations.is_followed_by?(station, current_user) do
      conn |> put_status(:ok) |> json(%{following: result})
    end
  end
end
