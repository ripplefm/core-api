defmodule RippleWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use RippleWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(RippleWeb.ChangesetView, "error.json", changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> render(RippleWeb.ErrorView, :"404")
  end

  def call(conn, {:error, :not_playlist_creator}) do
    conn
    |> put_status(:forbidden)
    |> render(RippleWeb.ErrorView, :"403", message: "Must be playlist creator")
  end

  def call(conn, {:error, :playlist_not_found}) do
    conn
    |> put_status(:not_found)
    |> render(RippleWeb.ErrorView, :"404", message: "Playlist not found")
  end

  def call(conn, {:error, :track_not_in_playlist}) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(RippleWeb.ErrorView, :"422", message: "Track not in playlist")
  end
end
