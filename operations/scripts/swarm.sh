#!/usr/bin/env bash
set -euo pipefail

read -r -a manager_hosts <<<"${MANAGER_HOSTS:?required}"

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
  local primary_host="${PRIMARY_HOST:?required}"
  local advertise_addr="${ADVERTISE_ADDR:?required}"
  local manager_endpoint="${MANAGER_ENDPOINT:?required}"
  for host in "${manager_hosts[@]}"; do
    ssh -o StrictHostKeyChecking=accept-new "$host" true
  done

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
  docker --host "$(swarm_manager_host)" node ls --format 'table {{.Hostname}}\t{{.Status}}\t{{.Availability}}\t{{.ManagerStatus}}\t{{.EngineVersion}}'
}

drain() {
  local manager listing node state tasks attempt busy
  local -a nodes=()
  manager=$(swarm_manager_host)
  listing=$(docker --host "$manager" node ls --quiet)
  mapfile -t nodes <<<"$listing"
  if [[ -z $listing ]]; then
    printf 'No Swarm nodes found.\n' >&2
    return 1
  fi

  for node in "${nodes[@]}"; do
    state=$(docker --host "$manager" node inspect --format '{{.Status.State}}' "$node")
    if [[ $state != ready ]]; then
      printf 'Node %s is %s; cannot verify its tasks have stopped.\n' "$node" "$state" >&2
      return 1
    fi
  done

  for node in "${nodes[@]}"; do
    docker --host "$manager" node update --availability drain "$node"
  done

  for ((attempt = 0; attempt < 300; attempt++)); do
    busy=false
    for node in "${nodes[@]}"; do
      state=$(docker --host "$manager" node inspect --format '{{.Status.State}}|{{.Spec.Availability}}' "$node")
      if [[ $state != 'ready|drain' ]]; then
        printf 'Node %s is no longer ready and drained: %s\n' "$node" "$state" >&2
        return 1
      fi
      tasks=$(docker --host "$manager" node ps --no-trunc --format '{{.CurrentState}}' "$node")
      if grep -Eq '^(New|Pending|Assigned|Accepted|Preparing|Ready|Starting|Running)( |$)' <<<"$tasks"; then
        busy=true
      fi
    done
    if [[ $busy == false ]]; then
      printf 'All Swarm nodes are drained. Reactivate them manually after recovery.\n'
      printf 'Standalone containers and the backup timer are not stopped.\n'
      return
    fi
    sleep 1
  done
  printf 'Timed out waiting for Swarm tasks to stop. Nodes remain drained.\n' >&2
  return 1
}

services_remove() {
  local manager listing name count answer number
  local -a stacks=() selected=() numbers=()
  manager="$(swarm_manager_host)"
  if [[ -n ${1:-} ]]; then
    docker --host "$manager" stack rm --detach=false -- "$1"
    return
  fi
  listing="$(docker --host "$manager" stack ls --format '{{.Name}}\t{{.Services}}')"
  if [[ -z $listing ]]; then
    printf 'No deployed stacks.\n'
    return
  fi
  printf 'Remove stacks\n\n'
  while IFS=$'\t' read -r name count; do
    stacks+=("$name")
    printf '  %d) %-24s services: %s\n' "${#stacks[@]}" "$name" "$count"
  done <<<"$listing"
  printf '\n'
  read -r -p 'Choose numbers separated by spaces (e.g. 1 3), or Enter to cancel: ' answer || return 0
  read -r -a numbers <<<"$answer"
  ((${#numbers[@]})) || return 0
  count=${#stacks[@]}
  for number in "${numbers[@]}"; do
    if [[ ! $number =~ ^[1-9][0-9]*$ ]] || ((${#number} > ${#count})) || ((number > count)); then
      printf 'Invalid selection: %s\n' "$number" >&2
      return 1
    fi
    name=${stacks[number - 1]}
    [[ " ${selected[*]} " == *" $name "* ]] || selected+=("$name")
  done
  printf '\nRemove these stacks:\n'
  printf '  %s\n' "${selected[@]}"
  printf '\nAll their services will be removed. Persistent volumes are kept.\n'
  read -r -p 'Remove selected stacks? [y/N] ' answer || return 0
  [[ $answer =~ ^[yY]([eE][sS])?$ ]] || return 0
  docker --host "$manager" stack rm --detach=false -- "${selected[@]}"
  printf 'Removed %d stacks.\n' "${#selected[@]}"
}

rebuild() {
  local primary_host="${PRIMARY_HOST:?required}"
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
  init | status | rebuild | drain)
    "$1"
    ;;
  services-remove)
    services_remove "${@:2}"
    ;;
  *)
    printf 'Usage: %s {init|status|rebuild|drain|services-remove [STACK]}\n' "$0" >&2
    exit 1
    ;;
esac
