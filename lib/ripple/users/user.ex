defmodule Ripple.Users.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ripple.Users.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Poison.Encoder, only: [:id, :username]}
  schema "users" do
    field(:username, :string)
    field(:scopes, {:array, :string}, virtual: true, default: [])
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:id, :username])
    |> validate_required([:username])
    |> unique_constraint(:username)
  end
end
