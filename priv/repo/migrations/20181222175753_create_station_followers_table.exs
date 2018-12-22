defmodule Ripple.Repo.Migrations.CreateStationFollowersTable do
  use Ecto.Migration

  def change do
    create table(:station_followers, primary_key: false) do
      add(:station_id, references(:stations, on_delete: :nothing, type: :binary_id), null: false)
      add(:user_id, references(:users, on_delete: :nothing, type: :binary_id), null: false)

      timestamps()
    end

    create(unique_index(:station_followers, [:station_id, :user_id]))
  end
end
