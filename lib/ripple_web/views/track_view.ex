defmodule RippleWeb.TrackView do
  use RippleWeb, :view

  alias RippleWeb.UserView

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
      dj: render_one(track.dj, UserView, "user.json"),
      url: track.url,
      poster: track.poster,
      name: track.name,
      current_time: :os.system_time(:millisecond) - track.timestamp,
      provider: track.provider
    }
  end

  def render("track_hidden.json", %{track: track}) do
    %{
      dj: %{
        username: track.dj.username,
        id: track.dj.id
      }
    }
  end

  def render("track_history.json", %{track: track}) do
    %{
      artwork_url: track.artwork_url,
      duration: track.duration,
      dj: render_one(track.dj, UserView, "user.json"),
      started_at: track.started_at,
      finished_at: track.finished_at,
      name: track.name,
      provider: track.provider,
      url: track.url
    }
  end
end
