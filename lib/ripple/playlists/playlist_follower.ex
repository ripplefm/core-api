defmodule Ripple.Playlists.PlaylistFollower do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Ripple.Playlists.PlaylistFollower

  @primary_key false
  schema "playlist_followers" do
    field(:playlist_id, :id)
    field(:user_id, :binary_id)

    timestamps()
  end

  def changeset(%PlaylistFollower{} = follower, attrs) do
    follower
    |> cast(attrs, [:playlist_id, :user_id])
    |> validate_required([:playlist_id, :user_id])
    |> unique_constraint(:playlist_id)
    |> unique_constraint(:user_id)
  end

  def build(playlist_id, user_id) do
    changeset(%PlaylistFollower{}, %{
      playlist_id: playlist_id,
      user_id: user_id
    })
  end

  def find(playlist_id, user_id) do
    from(f in PlaylistFollower, where: f.playlist_id == ^playlist_id, where: f.user_id == ^user_id)
  end
end
