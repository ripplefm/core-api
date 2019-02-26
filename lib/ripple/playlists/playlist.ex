defmodule Ripple.Playlists.Playlist do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Ripple.Playlists.{Playlist, PlaylistFollower}

  schema "playlists" do
    field(:name, :string)
    field(:slug, :string)
    field(:visibility, :string)
    belongs_to(:creator, Ripple.Users.User, type: :binary_id)
    many_to_many(:tracks, Ripple.Tracks.Track, join_through: "playlist_tracks")
    field(:followers, :integer, virtual: true, default: 0)

    timestamps()
  end

  @doc false
  def changeset(%Playlist{} = playlist, attrs) do
    playlist
    |> cast(attrs, [:name, :visibility, :creator_id])
    |> validate_required([:name, :visibility, :creator_id])
    |> validate_length(:name, min: 2)
    |> validate_inclusion(:visibility, ["public", "private"])
    |> generate_slug
    |> validate_required([:slug])
    |> unique_constraint(:slug)
  end

  defp generate_slug(changeset) do
    case get_field(changeset, :visibility) do
      "private" -> put_change(changeset, :slug, Ecto.UUID.generate() |> binary_part(24, 8))
      "public" -> put_change(changeset, :slug, Slug.slugify(get_field(changeset, :name)))
      _ -> changeset
    end
  end

  def all_playlists do
    from(p in Playlist,
      left_join: creator in Ripple.Users.User,
      on: creator.id == p.creator_id,
      left_join: follower in PlaylistFollower,
      on: follower.playlist_id == p.id,
      select: %{p | followers: fragment("count(?)", follower.user_id)},
      group_by: [p.id, follower.playlist_id, creator.id],
      order_by: [desc: fragment("count(?)", follower.user_id)],
      preload: [creator: creator]
    )
  end

  def with_public_visibility(queryable \\ Playlist) do
    from(p in queryable, where: p.visibility == "public")
  end

  def created_by(queryable \\ Playlist, user_id) do
    from(p in queryable, where: p.creator_id == ^user_id)
  end

  def followed_by(queryable \\ Playlist, user_id) do
    from(p in queryable,
      join: follower in PlaylistFollower,
      on: follower.playlist_id == p.id,
      where: follower.user_id == ^user_id
    )
  end

  def with_slug(queryable \\ Playlist, slug) do
    from(p in queryable, where: p.slug == ^slug)
  end
end
