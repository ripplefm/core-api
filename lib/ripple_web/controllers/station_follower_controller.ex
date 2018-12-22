defmodule RippleWeb.StationFollowerController do
  use RippleWeb, :controller

  alias Ripple.Stations.StationFollower
  alias Ripple.Stations

  import RippleWeb.Helpers.AuthHelper

  action_fallback(RippleWeb.FallbackController)
  plug(:require_current_user)
  plug(:authorize_resource, model: StationFollower, non_id_actions: [:create, :delete])

  def create(conn, %{"slug" => slug}) do
    current_user = conn.assigns.current_user

    with {:ok, station} <- Stations.get_station(slug),
         {:ok, %StationFollower{}} <- Stations.follow_station(station, current_user) do
      conn |> send_resp(:created, "")
    end
  end

  def delete(conn, %{"slug" => slug}) do
    current_user = conn.assigns.current_user

    with {:ok, station} <- Stations.get_station(slug),
         :ok <- Stations.unfollow_station(station, current_user) do
      conn |> send_resp(:no_content, "")
    end
  end
end
