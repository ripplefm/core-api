defmodule RippleWeb.PlaylistFollowerController do
  use RippleWeb, :controller

  alias Ripple.Playlists.PlaylistFollower
  alias Ripple.Playlists

  import RippleWeb.Helpers.AuthHelper

  action_fallback(RippleWeb.FallbackController)
  plug(:require_current_user)
  plug(:authorize_resource, model: PlaylistFollower, non_id_actions: [:create, :delete])

  def create(conn, %{"slug" => slug}) do
    current_user = conn.assigns.current_user

    with {:ok, playlist} <- Playlists.get_playlist_for_user(slug, current_user),
         {:ok, %PlaylistFollower{}} <- Playlists.follow_playlist(playlist, current_user) do
      conn |> send_resp(:created, "")
    end
  end

  def delete(conn, %{"slug" => slug}) do
    current_user = conn.assigns.current_user

    with {:ok, playlist} <- Playlists.get_playlist_for_user(slug, current_user),
         :ok <- Playlists.unfollow_playlist(playlist, current_user) do
      conn |> send_resp(:no_content, "")
    end
  end
end
