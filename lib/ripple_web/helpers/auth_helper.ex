defmodule RippleWeb.Helpers.AuthHelper do
  def set_current_user(conn, _) do
    with {:ok, claims} <- Map.fetch(conn.assigns, :joken_claims) do
      current_user = %{
        scopes: claims["scopes"],
        username: claims["user"]["username"],
        id: claims["user"]["id"]
      }

      Ripple.Users.upsert_user(current_user)

      conn |> Plug.Conn.assign(:current_user, current_user)
    else
      :error -> conn |> Plug.Conn.assign(:current_user, nil)
    end
  end

  def require_current_user(conn, _) do
    case Map.fetch(conn.assigns, :current_user) do
      {:ok, nil} -> unauthorized(conn, "Missing or invalid token in Authorization header.")
      {:ok, _} -> conn
      _ -> unauthorized(conn, "Missing or invalid token in Authorization header.")
    end
  end

  def unauthorized(conn) do
    unauthorized(conn, "Invalid scopes for resource.")
  end

  def unauthorized(conn, reason) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(401, Poison.encode!(%{error: reason}))
    |> Plug.Conn.halt()
  end
end
