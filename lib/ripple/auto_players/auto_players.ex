defmodule Ripple.AutoPlayers do
  alias Ripple.Repo
  alias Ripple.AutoPlayers.AutoPlayerConfig

  def create_config(%{} = station, %{} = sources) do
    %AutoPlayerConfig{}
    |> AutoPlayerConfig.changeset(%{station: station, play_sources: sources})
    |> Repo.insert()
  end

  def upsert_config(%{} = station, %{} = sources) do
    %AutoPlayerConfig{}
    |> AutoPlayerConfig.changeset(%{station: station, play_sources: sources})
    |> Repo.insert(on_conflict: :replace_all, conflict_target: :station_id)
  end

  def get_config_for_station(%{} = station) do
    AutoPlayerConfig |> Repo.get_by(station_id: station.id)
  end
end
