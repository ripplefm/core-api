defmodule Ripple.Repo.Migrations.CreatePlaylistTracks do
  use Ecto.Migration

  def change do
    create table(:playlist_tracks, primary_key: false) do
      add(:playlist_id, references(:playlists), primary_key: true)
      add(:track_id, references(:tracks), primary_key: true)

      timestamps()
    end

    create(unique_index(:playlist_tracks, [:playlist_id, :track_id]))
  end
end
