#!/usr/bin/env bash

set -euo pipefail

: "${SWARM_PRIMARY:?SWARM_PRIMARY is required}"
: "${SWARM_JOIN_HOSTS:?SWARM_JOIN_HOSTS is required}"
: "${SWARM_ADVERTISE_ADDR:?SWARM_ADVERTISE_ADDR is required}"
: "${SWARM_MANAGER_ENDPOINT:?SWARM_MANAGER_ENDPOINT is required}"

printf '+ ssh %s sudo docker swarm init\n' \
  "${SWARM_PRIMARY}"

primary_state="$(
  ssh "${SWARM_PRIMARY}" \
    sudo docker info --format '{{.Swarm.LocalNodeState}}'
)"

if [[ ${primary_state} == "active" ]]; then
  printf 'swarm already active on %s, skipping init\n' \
    "${SWARM_PRIMARY}"
else
  ssh "${SWARM_PRIMARY}" \
    sudo docker swarm init \
    --advertise-addr "${SWARM_ADVERTISE_ADDR}"
fi

printf '\n+ ssh %s sudo docker swarm join-token -q manager\n' \
  "${SWARM_PRIMARY}"

manager_token="$(
  ssh "${SWARM_PRIMARY}" \
    sudo docker swarm join-token -q manager
)"

for host in ${SWARM_JOIN_HOSTS}; do
  host_state="$(
    ssh "${host}" \
      sudo docker info --format '{{.Swarm.LocalNodeState}}'
  )"

  if [[ ${host_state} == "active" ]]; then
    printf '\nswarm already active on %s, skipping join\n' \
      "${host}"
    continue
  fi

  printf '\n+ ssh %s sudo docker swarm join --token <redacted> %s\n' \
    "${host}" \
    "${SWARM_MANAGER_ENDPOINT}"

  ssh "${host}" \
    sudo docker swarm join \
    --token "${manager_token}" \
    "${SWARM_MANAGER_ENDPOINT}"
done

printf '\n+ ssh %s sudo docker node ls\n' \
  "${SWARM_PRIMARY}"

ssh "${SWARM_PRIMARY}" \
  sudo docker node ls
