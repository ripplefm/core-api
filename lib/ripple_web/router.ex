defmodule RippleWeb.Router do
  use RippleWeb, :router
  import RippleWeb.Helpers.{JWTHelper, AuthHelper}

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:optional_verify)
    plug(:set_current_user)
  end

  scope "/", RippleWeb do
    pipe_through(:api)
  end
end
