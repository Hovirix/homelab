#!/usr/bin/env bash
set -euo pipefail

: "${DOCKER_HOST:?required}"
: "${SWARM_JOIN_DOCKER_HOSTS:?required}"
: "${SWARM_ADVERTISE_ADDR:?required}"
: "${SWARM_MANAGER_ENDPOINT:?required}"

printf 'Checking primary node: %s\n' "$DOCKER_HOST"

primary_state="$(docker --host "$DOCKER_HOST" info --format '{{.Swarm.LocalNodeState}}')"

if [[ $primary_state == "active" ]]; then
  printf 'Swarm is already initialized.\n'
else
  printf 'Initializing swarm...\n'
  docker --host "$DOCKER_HOST" swarm init --advertise-addr "$SWARM_ADVERTISE_ADDR"
fi

printf 'Retrieving manager join token...\n'

SWARM_TOKEN="$(docker --host "$DOCKER_HOST" swarm join-token --quiet manager)"

for host in $SWARM_JOIN_DOCKER_HOSTS; do
  printf '\nChecking node: %s\n' "$host"

  node_state="$(docker --host "$host" info --format '{{.Swarm.LocalNodeState}}')"

  if [[ $node_state == "active" ]]; then
    printf 'Node is already part of a swarm; skipping.\n'
  else
    printf 'Joining node as a manager...\n'
    docker --host "$host" swarm join --token "$SWARM_TOKEN" "$SWARM_MANAGER_ENDPOINT"
  fi
done

printf '\nCurrent swarm nodes:\n'

docker --host "$DOCKER_HOST" node ls
