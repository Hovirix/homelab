#!/bin/sh
set -eu

export NTFY_GRAFANA_TOKEN
NTFY_GRAFANA_TOKEN="$(cat /run/secrets/ntfy_grafana_token)"
exec /run.sh
