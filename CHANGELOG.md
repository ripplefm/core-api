# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2019-03-24

### Changed

- Station auto players now fetch all videos in YouTube channel and playlist before selecting next track

### Fixed

- Live stations no longer have empty tags

## [0.3.0] - 2019-03-20

### Added

- Stations now have live reactions for current tracks

## [0.2.1] - 2019-03-02

### Fixed

- Endpoints for user created stations now return valid information when a station is live
- Follower count on live stations is now updated when a station is followed/unfollowed

## [0.2.0] - 2019-03-01

### Fixed

- Stations context had functions that required `Station` struct but were sometimes passed a `LiveStation` struct and threw `FunctionClauseErrors`

### Added

- Endpoint and Station context function to check if the current user is following a station

## [0.1.11] - 2019-02-27

### Added

- Seed release task, can be ran using `bin/ripple seed`

## [0.1.10] - 2019-02-27

### Fixed

- Fix calls to `Stations.get_station/2` to handle updated tuple returns

## [0.1.9] - 2019-02-27

### Fixed

- priv directory path access in `seeds.exs` is not hardcoded anymore

## [0.1.8] - 2019-02-26

### Added

- Endpoints for the `me` resource to retrieve current users
  created and followed stations/playlists

## [0.1.7] - 2019-02-26

### Added

- Users can now follow stations and playlists

## [0.1.6] - 2019-02-25

### Added

- Stations context has function to get all public stations created by a user
- Stations created by user `autoplayer` are automatically started
- Auto player servers are started for stations created by `autoplayer` to play tracks defined in auto player configs

## [0.1.5] - 2018-12-21

### Added

- Stations now save track history and current track in postgres
- `/stations/:slug/history` endpoint for fetching station track history

## [0.1.4] - 2018-11-23

### Changed

- Station field `play_type` renamed to `visibility`

## [0.1.3] - 2018-11-23

### Fixed

- Websockets are now accepted from all origins
- Poison no longer throws exceptions when decoding tracks and users

## [0.1.2] - 2018-11-19

### Fixed

- CORs plug now works for all origins

## [0.1.1] - 2018-11-16

### Changed

- libcluster `:enabled` app setting now moved to `CLUSTER_ENABLED` environment variable to allow running production docekr image without a cluster.

### Removed

- No longer proxying requests to auth service for `/users/me`

## [0.1.0] - 2018-11-14

### Added

- Chat messages are now processed and sent back as an array of message types. For example, the message `@daniel check out this link: https://ripple.fm` will be processed as:
  ```
  [
    %{ type: "mention", value: "@daniel" },
    %{ type: "text", value: "check out this link:" },
    %{ type: "link", value: "https://ripple.fm" }
  ]
  ```

## [0.0.3] - 2018-11-14

### Added

- Station servers now save state when killed and restore state when restarted, state handoff works in a clustered environment

### Fixed

- Exception with station `users` array and Poison json encoding is fixed by implementing `UserView`

## [0.0.2] - 2018-11-13

### Added

- Ecto migrations are now a release task and run as a pre_start hook in distillery releases
- Station servers are now supervised by Horde and restart on a new node if the running node dies (restarted with new state for now)

## [0.0.1] - 2018-10-04

### Added

- Deployments (docker images) now automatically join and leave cluster when running in Production on Kubernetes
