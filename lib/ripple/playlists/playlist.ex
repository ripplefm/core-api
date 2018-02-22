defmodule Ripple.Playlists.Playlist do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ripple.Playlists.Playlist

  schema "playlists" do
    field(:name, :string)
    field(:slug, :string)
    field(:visibility, :string)
    belongs_to(:creator, Ripple.Users.User, type: :binary_id)
    many_to_many(:tracks, Ripple.Tracks.Track, join_through: "playlist_tracks")

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
end
