#!/bin/bash
set -e

# check formatting
mix format --check-formatted

# run tests
mix test
