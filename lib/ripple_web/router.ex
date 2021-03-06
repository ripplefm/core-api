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

    get("/stations/:slug/history", StationHistoryController, :show, param: "slug")
    post("/stations/:slug/followers", StationFollowerController, :create, param: "slug")
    delete("/stations/:slug/followers", StationFollowerController, :delete, param: "slug")

    post("/playlists/:slug", PlaylistController, :add, param: "slug")
    delete("/playlists/:slug", PlaylistController, :remove, param: "slug")
    resources("/playlists", PlaylistController, only: [:create, :show], param: "slug")
    post("/playlists/:slug/followers", PlaylistFollowerController, :create, param: "slug")
    delete("/playlists/:slug/followers", PlaylistFollowerController, :delete, param: "slug")

    get("/me/stations", MeController, :show_created_stations)
    get("/me/stations/following", MeController, :show_following_stations)
    get("/me/playlists", MeController, :show_created_playlists)
    get("/me/playlists/following", MeController, :show_following_playlists)
    get("/me/stations/:slug/following", MeController, :get_is_following_station, param: "slug")
  end
end
