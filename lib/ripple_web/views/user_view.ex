defmodule RippleWeb.UserView do
  use RippleWeb, :view

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      username: user.username
    }
  end
end
