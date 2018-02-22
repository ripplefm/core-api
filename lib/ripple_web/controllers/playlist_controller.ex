defmodule RippleWeb.PlaylistController do
  use RippleWeb, :controller

  alias Ripple.Playlists
  alias Ripple.Playlists.Playlist

  import RippleWeb.Helpers.AuthHelper

  action_fallback(RippleWeb.FallbackController)
  plug(:require_current_user when action in [:create, :add, :remove])

  plug(
    :load_and_authorize_resource,
    model: Playlist,
    id_name: "slug",
    id_field: "slug"
  )

  def create(conn, %{"playlist" => playlist_params}) do
    user = conn.assigns.current_user

    with {:ok, %Playlist{} = playlist} <-
           Playlists.create_playlist(Map.put(playlist_params, "creator_id", user.id)) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", playlist_path(conn, :show, playlist))
      |> render(:created, playlist: playlist, creator: conn.assigns.current_user)
    end
  end

  def show(conn, %{"slug" => slug}) do
    user = conn.assigns.current_user

    with {:ok, playlist} <- Playlists.get_playlist_for_user(slug, user) do
      render(conn, :show, playlist: playlist)
    end
  end

  def add(conn, %{"slug" => slug, "track_url" => track_url}) do
    user = conn.assigns.current_user

    with {:ok, track} <- Playlists.add_track_to_playlist(user, slug, track_url) do
      conn
      |> put_status(:created)
      |> render(RippleWeb.TrackView, :track, track: track)
    end
  end

  def remove(conn, %{"slug" => slug, "track_url" => track_url}) do
    user = conn.assigns.current_user

    with {:ok, _} <- Playlists.remove_track_from_playlist(user, slug, track_url) do
      send_resp(conn, :no_content, "")
    end
  end
end
