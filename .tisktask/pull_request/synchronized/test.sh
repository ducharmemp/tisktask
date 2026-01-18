#!/usr/bin/env bash

set -eou pipefail

redis-cli -s "$TISKTASK_SOCKET_PATH" SPAWNCONTAINER postgres

mix test

