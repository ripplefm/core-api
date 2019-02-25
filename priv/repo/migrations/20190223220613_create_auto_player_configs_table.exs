defmodule Ripple.Repo.Migrations.CreateAutoPlayerConfigsTable do
  use Ecto.Migration

  def change do
    create table(:auto_player_configs, primary_key: false) do
      add(:station_id, references(:stations, on_delete: :nothing, type: :binary_id), null: false)
      add(:play_sources, :map, null: false)
    end

    create(unique_index(:auto_player_configs, [:station_id]))
  end
end
