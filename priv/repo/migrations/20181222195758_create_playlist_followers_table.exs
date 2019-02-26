defmodule Ripple.Repo.Migrations.CreatePlaylistFollowersTable do
  use Ecto.Migration

  def change do
    create table(:playlist_followers, primary_key: false) do
      add(:playlist_id, references(:playlists, on_delete: :nothing), null: false)

      add(:user_id, references(:users, on_delete: :nothing, type: :binary_id), null: false)

      timestamps()
    end

    create(unique_index(:playlist_followers, [:playlist_id, :user_id]))
  end
end
