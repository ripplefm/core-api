defmodule RippleWeb.Helpers.JWTHelper do
  import Joken

  @private_key JOSE.JWK.from_pem_file(System.get_env("PRIVATE_KEY_LOCATION"))
  @key JOSE.JWK.from_pem_file(System.get_env("PUBLIC_KEY_LOCATION"))

  def optional_verify(conn, _) do
    with [auth_header] <- Plug.Conn.get_req_header(conn, "authorization"),
         {:ok, claims} <- verify_header(auth_header) do
      conn |> Plug.Conn.assign(:joken_claims, claims)
    else
      _ -> conn
    end
  end

  def verify_token(jwt) do
    jwt
    |> token
    |> with_json_module(Poison)
    |> with_signer(rs256(@key))
    |> with_validation("iss", &(&1 == "ripple.fm"))
    |> with_validation("iat", &(&1 <= current_time()))
    |> with_validation("exp", &(&1 > current_time()))
    |> verify!
  end

  # for tests
  def sign(claims) do
    claims
    |> token
    |> with_iss("ripple.fm")
    |> with_iat(current_time() - 300)
    |> with_exp(current_time() + 1800)
    |> sign(rs256(@private_key))
    |> get_compact
  end

  defp verify_header(header) do
    header
    |> String.slice(String.length("Bearer "), String.length(header))
    |> verify_token
  end
end
