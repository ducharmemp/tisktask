#!/usr/bin/env bash

set -eoux pipefail

redis-cli -s /run/tisktask/command.sock SPAWNCONTAINER postgres:17 POSTGRES_PASSWORD=postgres

mix test
