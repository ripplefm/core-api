defmodule RippleWeb.StationChannel do
  use RippleWeb, :channel

  alias Ripple.Stations
  alias Ripple.Stations.{StationStore, StationServer}
  alias RippleWeb.Helpers.ChatHelper

  @allowed_reactions ["fire", "thumbs-up", "thumbs-down", "rock-on", "poop"]

  def join("stations:" <> slug, _payload, socket) do
    case StationStore.read(slug) do
      {:ok, nil} ->
        StationServer.start(Stations.get_station!(slug), socket.assigns.current_user)

      {:ok, _} ->
        StationServer.add_user(slug, socket.assigns.current_user)
    end

    {:ok, socket}
  end

  def terminate(_reason, socket) do
    socket
    |> get_slug
    |> StationServer.remove_user(socket.assigns.current_user)

    {:ok, socket}
  end

  def handle_in("track", %{"track_url" => url}, socket) do
    unless socket.assigns.current_user == nil do
      socket
      |> get_slug
      |> StationServer.add_track(url, socket.assigns.current_user)
    end

    {:noreply, socket}
  end

  def handle_in("chat", %{"text" => text}, socket) do
    unless socket.assigns.current_user == nil do
      broadcast(socket, "station_chat", %{
        sender: socket.assigns.current_user,
        message: ChatHelper.process(text)
      })
    end

    {:noreply, socket}
  end

  def handle_in("reaction", %{"reaction" => reaction}, socket) do
    station = socket |> get_slug |> StationServer.get()

    unless socket.assigns.current_user == nil or reaction not in @allowed_reactions or
             station.current_track == nil do
      broadcast(socket, "station_reaction", %{
        sender: socket.assigns.current_user,
        reaction: reaction
      })
    end

    {:noreply, socket}
  end

  defp get_slug(socket) do
    ["stations", slug] = String.split(socket.topic, ":")
    slug
  end
end
