#!/usr/bin/env bash

set -eoux pipefail

redis-cli -s "$TISKTASK_SOCKET_PATH" SPAWNCONTAINER postgres:17 POSTGRES_PASSWORD=postgres

mix test
