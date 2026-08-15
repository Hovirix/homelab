#!/usr/bin/env bash
set -euo pipefail

hosts=(
  ssh://deploy@swarm-01.home.hovirix.dev
  ssh://deploy@swarm-02.home.hovirix.dev
  ssh://deploy@swarm-03.home.hovirix.dev
)

for host in "${hosts[@]}"; do
  if [[ $(docker --host "$host" info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null) == "active" ]]; then
    if [[ ${1:-} == "--export" ]]; then
      printf 'export DOCKER_HOST=%q\n' "$host"
    else
      printf '%s\n' "$host"
    fi
    exit 0
  fi
done

printf 'No active Swarm manager reachable.\n' >&2
exit 1
