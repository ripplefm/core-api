defmodule Ripple.Tracks.Track do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ripple.Tracks.Track

  schema "tracks" do
    field(:artwork_url, :string)
    field(:duration, :integer)
    field(:name, :string)
    field(:poster, :string)
    field(:provider, :string)
    field(:url, :string)

    timestamps()
  end

  @doc false
  def changeset(%Track{} = track, attrs) do
    track
    |> cast(attrs, [:name, :artwork_url, :duration, :poster, :provider, :url])
    |> validate_required([:name, :artwork_url, :duration, :poster, :provider, :url])
    |> validate_inclusion(:provider, ["YouTube", "SoundCloud"])
    |> unique_constraint(:url)
  end
end
