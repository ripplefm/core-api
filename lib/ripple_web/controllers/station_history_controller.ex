defmodule RippleWeb.StationHistoryController do
  use RippleWeb, :controller

  alias Ripple.Stations

  action_fallback(RippleWeb.FallbackController)

  def show(conn, %{"slug" => slug, "last_timestamp" => last_timestamp}) do
    with {:ok, history} <- Stations.get_history(slug, last_timestamp) do
      render(conn, "show.json", history: history)
    end
  end

  def show(conn, %{"slug" => slug}) do
    with {:ok, history} <- Stations.get_history(slug) do
      render(conn, "show.json", history: history)
    end
  end
end
