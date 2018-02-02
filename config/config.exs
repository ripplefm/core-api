# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :ripple,
  ecto_repos: [Ripple.Repo]

# Configures the endpoint
config :ripple, RippleWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "RA/SXqionW9mrmyQ/mfdW523aLEAsPrg8IRts2x4+UPVYKLEYIEedRo0uiF0iL+W",
  render_errors: [view: RippleWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Ripple.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
