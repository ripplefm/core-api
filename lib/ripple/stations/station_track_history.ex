defmodule Ripple.Stations.StationTrackHistory do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

  alias Ripple.Stations.StationTrackHistory
  alias Ripple.Tracks.Track
  alias Ripple.Users.User

  @primary_key false
  schema "station_track_history" do
    field(:station_id, :binary_id)
    field(:user_id, :binary_id)
    field(:track_id, :integer)
    timestamps(inserted_at: :started_at, updated_at: false)
    field(:finished_at, :naive_datetime, default: nil)
  end

  def changeset(%StationTrackHistory{} = history, attrs) do
    history
    |> cast(attrs, [:station_id, :user_id, :track_id])
    |> validate_required([:station_id, :user_id, :track_id])
  end

  def for_station(id) do
    from(h in StationTrackHistory,
      where: h.station_id == ^id,
      where: not is_nil(h.finished_at),
      join: t in Track,
      on: t.id == h.track_id,
      join: u in User,
      on: u.id == h.user_id,
      order_by: [desc: h.started_at],
      select: %{
        dj: u,
        artwork_url: t.artwork_url,
        duration: t.duration,
        started_at: h.started_at,
        finished_at: h.finished_at,
        url: t.url,
        poster: t.poster,
        name: t.name,
        provider: t.provider
      },
      limit: 10
    )
  end

  def older_than(queryable, last_timestamp) do
    from(q in queryable,
      where: q.finished_at < ^last_timestamp
    )
  end
end
