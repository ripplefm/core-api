# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
