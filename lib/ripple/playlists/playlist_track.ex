defmodule Ripple.Playlists.PlaylistTrack do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ripple.Playlists.PlaylistTrack

  @primary_key false
  schema "playlist_tracks" do
    field(:playlist_id, :integer)
    field(:track_id, :integer)

    timestamps()
  end

  def changeset(%PlaylistTrack{} = playlist, attrs) do
    playlist
    |> cast(attrs, [:playlist_id, :track_id])
    |> validate_required([:playlist_id, :track_id])
    |> unique_constraint(:playlist_id)
    |> unique_constraint(:track_id)
  end
end
