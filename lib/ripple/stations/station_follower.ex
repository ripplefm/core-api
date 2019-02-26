defmodule Ripple.Stations.StationFollower do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Ripple.Stations.StationFollower

  @primary_key false
  schema "station_followers" do
    field(:station_id, :binary_id)
    field(:user_id, :binary_id)

    timestamps()
  end

  def changeset(%StationFollower{} = follower, attrs) do
    follower
    |> cast(attrs, [:station_id, :user_id])
    |> validate_required([:station_id, :user_id])
    |> unique_constraint(:station_id)
    |> unique_constraint(:user_id)
  end

  def build(station_id, user_id) do
    changeset(%StationFollower{}, %{
      station_id: station_id,
      user_id: user_id
    })
  end

  def find(station_id, user_id) do
    from(f in StationFollower, where: f.station_id == ^station_id, where: f.user_id == ^user_id)
  end
end
