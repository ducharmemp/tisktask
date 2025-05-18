#!/usr/bin/env bash

set -eou pipefail

echo $CI
mix test
