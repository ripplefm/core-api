defmodule RippleWeb.UserSocket do
  use Phoenix.Socket

  alias RippleWeb.Helpers.JWTHelper

  ## Channels
  # channel "room:*", RippleWeb.RoomChannel
  channel("stations:*", RippleWeb.StationChannel)

  ## Transports
  transport(:websocket, Phoenix.Transports.WebSocket)
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(%{"token" => token}, socket) do
    with {:ok, claims} <- JWTHelper.verify_token(token) do
      current_user = %Ripple.Users.User{
        username: claims["user"]["username"],
        id: claims["user"]["id"]
      }

      {:ok, assign(socket, :current_user, current_user)}
    else
      _ -> :error
    end
  end

  def connect(_, socket) do
    {:ok, assign(socket, :current_user, nil)}
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     RippleWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(%{assigns: %{current_user: current_user}}) when not is_nil(current_user),
    do: current_user.id

  def id(_socket), do: nil
end
