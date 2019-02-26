defmodule Ripple.Stations.Station do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Ripple.Stations.{Station, StationFollower}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "stations" do
    field(:name, :string)
    field(:visibility, :string)
    field(:slug, :string)
    field(:tags, {:array, :string})
    field(:creator_id, :binary_id)
    field(:followers, :integer, virtual: true, default: 0)

    timestamps()
  end

  @doc false
  def changeset(%Station{} = station, attrs) do
    station
    |> cast(attrs, [:name, :visibility, :tags, :creator_id])
    |> validate_required([:name, :visibility, :tags, :creator_id])
    |> validate_length(:name, min: 4)
    |> validate_inclusion(:visibility, ["public", "private"])
    |> generate_slug
    |> validate_required([:slug])
    |> unique_constraint(:slug)
  end

  def find(slug) do
    from(s in Station,
      where: s.slug == ^slug,
      left_join: follower in StationFollower,
      on: follower.station_id == s.id,
      select: %{
        s
        | followers: fragment("count(?)", follower.user_id)
      },
      group_by: [s.id, follower.station_id],
      order_by: [desc: fragment("count(?)", follower.user_id)]
    )
  end

  defp generate_slug(changeset) do
    case get_field(changeset, :visibility) do
      "private" -> put_change(changeset, :slug, Ecto.UUID.generate() |> binary_part(24, 8))
      "public" -> put_change(changeset, :slug, Slug.slugify(get_field(changeset, :name)))
      _ -> changeset
    end
  end

  def all_stations do
    from(s in Station,
      left_join: creator in Ripple.Users.User,
      on: creator.id == s.creator_id,
      left_join: follower in StationFollower,
      on: follower.station_id == s.id,
      select: %{s | followers: fragment("count(?)", follower.user_id)},
      group_by: [s.id, follower.station_id],
      order_by: [desc: fragment("count(?)", follower.user_id)]
    )
  end

  def with_slug(queryable \\ Station, slug) do
    from(s in queryable, where: s.slug == ^slug)
  end

  def with_public_visibility(queryable \\ Station) do
    from(s in queryable, where: s.visibility == "public")
  end

  def created_by(queryable \\ Station, user_id) do
    from(s in queryable, where: s.creator_id == ^user_id)
  end

  def followed_by(queryable \\ Station, user_id) do
    from(s in queryable,
      left_join: follower in StationFollower,
      on: follower.station_id == s.id,
      where: follower.user_id == ^user_id
    )
  end
end
