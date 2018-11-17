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

    resources(
      "/stations",
      StationController,
      except: [:new, :edit, :update, :delete],
      param: "slug"
    )

    post("/playlists/:slug", PlaylistController, :add, param: "slug")
    delete("/playlists/:slug", PlaylistController, :remove, param: "slug")
    resources("/playlists", PlaylistController, only: [:create, :show], param: "slug")
  end
end
