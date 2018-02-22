defmodule Ripple.Repo.Migrations.CreatePlaylists do
  use Ecto.Migration

  def change do
    create table(:playlists) do
      add(:name, :string)
      add(:slug, :string)
      add(:visibility, :string)
      add(:creator_id, references(:users, on_delete: :nothing, type: :binary_id))

      timestamps()
    end

    create(index(:playlists, [:creator_id]))
    create(unique_index(:playlists, [:slug]))
  end
end
