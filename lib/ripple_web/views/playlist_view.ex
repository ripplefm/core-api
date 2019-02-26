defmodule RippleWeb.PlaylistView do
  use RippleWeb, :view

  alias RippleWeb.{PlaylistView, TrackView}

  def render("private.json", _) do
    %{
      error: "Playlist not found"
    }
  end

  def render("many.json", %{playlists: playlists}) do
    %{playlists: render_many(playlists, PlaylistView, "playlist.json")}
  end

  def render("show.json", %{playlist: playlist}) do
    render_one(playlist, PlaylistView, "playlist.json")
  end

  def render("created.json", %{playlist: playlist, creator: creator}) do
    %{
      name: playlist.name,
      slug: playlist.slug,
      visibility: playlist.visibility,
      tracks: [],
      creator: %{
        username: creator.username,
        id: creator.id
      }
    }
  end

  def render("playlist.json", %{playlist: playlist}) do
    %{
      name: playlist.name,
      slug: playlist.slug,
      creator: %{
        username: playlist.creator.username,
        id: playlist.creator.id
      },
      visibility: playlist.visibility,
      tracks: render_many(Map.get(playlist, :tracks, []), TrackView, "track.json")
    }
  end
end
