defmodule RippleWeb.TrackView do
  use RippleWeb, :view

  def render("track.json", %{track: track}) do
    %{
      artwork_url: track.artwork_url,
      duration: track.duration,
      url: track.url,
      poster: track.poster,
      name: track.name,
      provider: track.provider
    }
  end

  def render("current_track.json", %{track: nil}), do: nil

  def render("current_track.json", %{track: track}) do
    %{
      artwork_url: track.artwork_url,
      duration: track.duration,
      timestamp: track.timestamp,
      dj: track.dj,
      url: track.url,
      poster: track.poster,
      name: track.name,
      current_time: :os.system_time(:millisecond) - track.timestamp,
      provider: track.provider
    }
  end

  def render("track_hidden.json", %{track: track}) do
    %{
      username: track.dj.username,
      id: track.dj.id
    }
  end
end
