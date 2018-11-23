defmodule Ripple.Repo.Migrations.CreateStations do
  use Ecto.Migration

  def change do
    create table(:stations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string)
      add(:visibility, :string)
      add(:slug, :string)
      add(:tags, {:array, :string})
      add(:creator_id, references(:users, on_delete: :nothing, type: :binary_id))

      timestamps()
    end

    create(index(:stations, [:creator_id]))
    create(unique_index(:stations, [:slug]))
  end
end
