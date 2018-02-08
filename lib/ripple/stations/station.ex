defmodule Ripple.Stations.Station do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ripple.Stations.Station

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "stations" do
    field(:name, :string)
    field(:play_type, :string)
    field(:slug, :string)
    field(:tags, {:array, :string})
    field(:creator_id, :binary_id)

    timestamps()
  end

  @doc false
  def changeset(%Station{} = station, attrs) do
    station
    |> cast(attrs, [:name, :play_type, :tags, :creator_id])
    |> validate_required([:name, :play_type, :tags, :creator_id])
    |> validate_length(:name, min: 4)
    |> validate_inclusion(:play_type, ["public", "private"])
    |> generate_slug
    |> validate_required([:slug])
    |> unique_constraint(:slug)
  end

  defp generate_slug(changeset) do
    case get_field(changeset, :play_type) do
      "private" -> put_change(changeset, :slug, Ecto.UUID.generate() |> binary_part(24, 8))
      "public" -> put_change(changeset, :slug, Slug.slugify(get_field(changeset, :name)))
      _ -> changeset
    end
  end
end
