defmodule RippleWeb.Router do
  use RippleWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", RippleWeb do
    pipe_through(:api)
  end
end
