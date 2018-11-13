defmodule RippleWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import RippleWeb.Router.Helpers

      # The default endpoint for testing
      @endpoint RippleWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ripple.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Ripple.Repo, {:shared, self()})
    end

    Ripple.ClusterHelper.cleanup()

    conn =
      if tags[:authenticated] do
        {:ok, user} = Ripple.Users.upsert_user(%{username: "tester"})

        token =
          %{
            scopes: ["user:email:read", "playlists:write", "stations:write"],
            user: %{
              username: user.username,
              id: user.id
            }
          }
          |> RippleWeb.Helpers.JWTHelper.sign()

        conn =
          Phoenix.ConnTest.build_conn()
          |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")

        conn
      else
        Phoenix.ConnTest.build_conn()
      end

    {:ok, conn: conn}
  end
end
