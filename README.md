# ripple.fm core API

Provides a REST API for crud operations on stations/playlists and a websocket api for interacting with live stations.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Technologies](#technologies)
- [Development](#development)
  - [Formatting](#formatting)
  - [Database](#database)
  - [Setting up your environment](#setting-up-your-environment)
  - [Starting the service](#starting-the-service)
- [Production](#production)
  - [Deploying](#deploying)
  - [Notes on configuration](#notes-on-configuration)
  - [CLI](#cli)

# Prerequisites

- Elixir
- mix
- Phoenix
- Postgresql

# Technologies

This project was built with:

- [Elixir/Phoenix](https://phoenixframework.org/)
- [libcluster](https://github.com/bitwalker/libcluster) to automatically form distributed erlang clusters when running in production on Kubernetes
- [Horde](https://github.com/derekkraan/horde) to provide distributed supervisors and registry for processes. Used to ensure that a station is restarted on a new node if the process (or node) dies
- [lbm_kv](https://github.com/lindenbaum/lbm_kv) to easily set up distributed mnesia. Used for storing live station state and to hand off previous state when a station process starts on a new node
- [event_bus](https://github.com/otobus/event_bus) to emit and react to station events
- [distillery](https://github.com/bitwalker/distillery) to package releases

# Development

## Formatting

This project uses [mix format](https://hexdocs.pm/mix/master/Mix.Tasks.Format.html) for formatting. It's recommended to configure your editor to automatically format files.

Formatting is checked when Travis CI runs a build and may be checked locally using the following command:

```sh
$ mix format --check-formatted
```

## Database

### Setup

This project requires a Postgresql database to be running.

If you already have one running just ensure that the [config](config/dev.exs) has the correct credentials to connect to your database.

If you don't have one, you can quickly start a development Postgresql database using docker with the following command:

```sh
$ docker run -p "5432:5432" -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD="secret" -e POSTGRES_HOSTNAME=localhost -e POSTGRES_DB=ripple_dev postgres:9.6
```

The above command requires no changes to the config.

### Migrations

Once we have a database that we can connect to, we must run migrations to create our schema. We do this by running:

```sh
$ mix ecto.migrate
```

### Seeds

You may want to seed your database with stations that are automatically started and have auto players attached to play tracks. We can do this by editing the [station_templates.exs](priv/repo/seeds/station_templates.exs) file to configure the stations we want created. Once we are happy with the templates we can seed the database with the following command:

```sh
$ mix run priv/repo/seeds/seeds.exs
```

## Setting up your environment

We must first set the environment variables defined in [.env.example](.env.example).

The steps for defining your environment variables:

1. Copy `.env.exmaple` to `.env`
1. Update values for the variables
1. Source the environment using `source .env`

## Starting the service

Now that we loaded the environment variables we can start the service.

To start the server we run:

```sh
$ mix phx.server
```

We can also start the server with an attached interactive console using the command:

```sh
$ iex -S mix phx.server
```

Once started, the api will now be available at: http://localhost:4000

# Production

## Deploying

Travis CI will automatically build and push tagged commits (matching the version in `mix.exs`) to the docker image repository.

After an image is built and pushed, update the [helm chart for ripple.fm](https://github.com/ripplefm/charts) to set the updated tag for the core-api service.

## Notes on configuration

Some notes about deploying to production:

- Ensure `MIX_ENV` is set to `prod`
- Ensure `REPLACE_OS_VARS` is set to `true`

For clustering on Kubernetes in production we must:

1. Create a ServiceAccount, Role, and RoleBinding for libcluster to query the Kubernetes API and connect to other core-api pods. You can see an example of the manifests in the helm templates for ripple.fm [here](https://github.com/ripplefm/charts)
1. Set the environment variable `CLUSTER_ENABLED` to `true`
1. Set the `MY_POD_IP` environment variable to the Kubernetes pod ip as defined [here](https://kubernetes.io/docs/tasks/inject-data-application/environment-variable-expose-pod-information/)

## CLI

Distillery releases provide commands we can run on any node with a release. Some of the commands include:

- `bin/ripple remote_console` - Provides an interactive Elixir console on the current node, can be used to run queries, check state, etc.
- `bin/ripple migrate` - to run migrations
- `bin/ripple seed` - to run seeds
