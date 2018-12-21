defmodule Ripple.Repo.Migrations.CreateStationTrackHistoryTable do
  use Ecto.Migration

  def change do
    create table(:station_track_history, primary_key: false) do
      add(:station_id, references(:stations, on_delete: :nothing, type: :binary_id), null: false)
      add(:user_id, references(:users, on_delete: :nothing, type: :binary_id), null: false)
      add(:track_id, references(:tracks, on_delete: :nothing), null: false)
      timestamps(inserted_at: :started_at, updated_at: false)
      add(:finished_at, :naive_datetime, default: nil)
    end
  end
end
