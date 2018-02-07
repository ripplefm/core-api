defmodule RippleWeb.UserController do
  use RippleWeb, :controller

  def me(conn, _params) do
    header =
      case get_req_header(conn, "authorization") do
        [auth_header] -> auth_header
        _ -> nil
      end

    {:ok, res} =
      HTTPoison.get(
        "#{System.get_env("AUTH_SERVICE_URL")}/api/users/me",
        authorization: header
      )

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(res.status_code, res.body)
  end
end
