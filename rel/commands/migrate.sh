#!/bin/sh

release_ctl eval --mfa "Ripple.ReleaseTasks.migrate/1" --argv -- "$@"
