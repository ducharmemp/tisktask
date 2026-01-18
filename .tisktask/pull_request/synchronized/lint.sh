#!/usr/bin/env bash

set -eou pipefail

mix format
mix credo
mix sobelow
