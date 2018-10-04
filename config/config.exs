# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :ripple, ecto_repos: [Ripple.Repo]

# Configures the endpoint
config :ripple, RippleWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "RA/SXqionW9mrmyQ/mfdW523aLEAsPrg8IRts2x4+UPVYKLEYIEedRo0uiF0iL+W",
  render_errors: [view: RippleWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Ripple.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configures Canary for authorization
config :canary,
  repo: Ripple.Repo,
  unauthorized_handler: {RippleWeb.Helpers.AuthHelper, :unauthorized},
  not_found_handler: {RippleWeb.Helpers.AuthHelper, :not_found}

# Configures event bus
config :event_bus,
  topics: [
    :station_started,
    :station_stopped,
    :station_user_joined,
    :station_user_left,
    :station_track_started,
    :station_track_finished,
    :station_queue_track_added
  ]

config :libcluster, enabled: false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
