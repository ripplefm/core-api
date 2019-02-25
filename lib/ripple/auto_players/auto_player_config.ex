defmodule Ripple.AutoPlayers.AutoPlayerConfig do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ripple.AutoPlayers.AutoPlayerConfig
  alias Ripple.Stations.Station

  @primary_key false
  schema "auto_player_configs" do
    belongs_to(:station, Station, type: :binary_id)
    field(:play_sources, :map)
  end

  def changeset(%AutoPlayerConfig{} = config, attrs) do
    config
    |> cast(attrs, [:play_sources])
    |> put_assoc(:station, attrs.station)
    |> validate_required([:play_sources, :station])
    |> unique_constraint(:station_id)
  end
end
