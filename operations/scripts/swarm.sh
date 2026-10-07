#!/usr/bin/env bash
set -euo pipefail

primary_host="${PRIMARY_HOST:?required}"
read -r -a manager_hosts <<<"${MANAGER_HOSTS:?required}"
advertise_addr="${ADVERTISE_ADDR:?required}"
manager_endpoint="${MANAGER_ENDPOINT:?required}"

swarm_manager_host() {
  for host in "${manager_hosts[@]}"; do
    if [[ $(docker --host "$host" info --format '{{.Swarm.LocalNodeState}}|{{.Swarm.ControlAvailable}}' 2>/dev/null) == "active|true" ]]; then
      printf '%s\n' "$host"
      return
    fi
  done

  printf 'No active Swarm manager reachable.\n' >&2
  return 1
}

is_active() {
  [[ $(docker --host "$1" info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null) == "active" ]]
}

init() {
  if ! is_active "$primary_host"; then
    printf 'Initializing swarm on %s\n' "$primary_host"
    docker --host "$primary_host" swarm init --advertise-addr "$advertise_addr"
  fi

  token="$(docker --host "$primary_host" swarm join-token --quiet manager)"

  for host in "${manager_hosts[@]:1}"; do
    if ! is_active "$host"; then
      printf 'Joining manager %s\n' "$host"
      docker --host "$host" swarm join --token "$token" "$manager_endpoint"
    fi
  done
}

status() {
  docker --host "$(swarm_manager_host)" node ls
}

rebuild() {
  for host in "${manager_hosts[@]:1}" "$primary_host"; do
    if is_active "$host"; then
      printf 'Leaving swarm on %s\n' "$host"
      docker --host "$host" swarm leave --force
    fi
  done

  init
}

case "${1:-}" in
  "")
    swarm_manager_host
    ;;
  init | status | rebuild)
    "$1"
    ;;
  *)
    printf 'Usage: %s {init|status|rebuild}\n' "$0" >&2
    exit 1
    ;;
esac
