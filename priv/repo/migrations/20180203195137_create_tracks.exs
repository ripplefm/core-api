defmodule Ripple.Repo.Migrations.CreateTracks do
  use Ecto.Migration

  def change do
    create table(:tracks) do
      add(:name, :string)
      add(:artwork_url, :string)
      add(:duration, :integer)
      add(:poster, :string)
      add(:provider, :string)
      add(:url, :string)

      timestamps()
    end

    create(unique_index(:tracks, [:url]))
  end
end
