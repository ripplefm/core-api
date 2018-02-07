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

    resources("/stations", StationController, [
      {:except, [:new, :edit, :update, :delete]},
      {:param, "slug"}
    ])

    get("/users/me", UserController, :me)
  end
end
