defmodule RippleWeb.StationView do
  use RippleWeb, :view
  alias RippleWeb.{StationView, TrackView}

  def render("index.json", %{stations: stations}) do
    %{stations: render_many(stations, StationView, "station_short.json")}
  end

  def render("show.json", %{station: station}) do
    render_one(station, StationView, "station.json")
  end

  def render("station_short.json", %{station: station}) do
    %{
      id: station.id,
      name: station.name,
      play_type: station.play_type,
      current_track:
        render_one(Map.get(station, :current_track, nil), TrackView, "current_track.json"),
      queue: Enum.count(Map.get(station, :queue, [])),
      tags: station.tags,
      users: Enum.count(station.users),
      guests: Map.get(station, :guests, 0),
      total_listeners: Enum.count(station.users) + Map.get(station, :guests, 0),
      slug: station.slug
    }
  end

  def render("station.json", %{station: station}) do
    %{
      id: station.id,
      name: station.name,
      slug: station.slug,
      play_type: station.play_type,
      tags: station.tags,
      current_track:
        render_one(Map.get(station, :current_track, nil), TrackView, "current_track.json"),
      queue: render_many(Map.get(station, :queue, []), TrackView, "track_hidden.json"),
      users: Map.get(station, :users, []),
      guests: Map.get(station, :guests, 0)
    }
  end
end
