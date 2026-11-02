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

stack_rm() {
  local stack="${1:?usage: swarm.sh stack-rm STACK}" manager
  manager="$(swarm_manager_host)"
  docker --host "$manager" stack rm --detach=false -- "$stack"
}

services_stop() {
  local manager listing name count answer number
  local -a stacks=() selected=() numbers=()
  manager="$(swarm_manager_host)"
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

assert_mounts_unused() {
  local mounts="$1" dataset mount target
  shift
  while IFS= read -r mount; do
    [[ -n $mount ]] || continue
    [[ $mount == / ]] || mount="${mount%/}"
    for dataset in "$@"; do
      target="/var/mnt/swarm/$dataset"
      if [[ $mount == / || $mount == "$target" || $mount == "$target/"* || $target == "$mount/"* ]]; then
        printf 'Dataset %s is still referenced by mount %s. Remove its consumers first.\n' "$dataset" "$mount" >&2
        return 1
      fi
    done
  done <<<"$mounts"
}

assert_unused() {
  local dataset manager ids mounts host
  local -a objects
  (($#)) || {
    printf 'Pass at least one dataset.\n' >&2
    return 1
  }
  for dataset in "$@"; do
    [[ $dataset =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]] || return 1
  done
  manager="$(swarm_manager_host)"
  ids="$(docker --host "$manager" service ls -q)"
  if [[ -n $ids ]]; then
    mapfile -t objects <<<"$ids"
    mounts="$(docker --host "$manager" service inspect --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{if not .ReadOnly}}{{println .Source}}{{end}}{{end}}' "${objects[@]}")"
    assert_mounts_unused "$mounts" "$@"
  fi
  for host in "${manager_hosts[@]}"; do
    ids="$(docker --host "$host" ps -q)"
    if [[ -n $ids ]]; then
      mapfile -t objects <<<"$ids"
      mounts="$(docker --host "$host" inspect --format '{{range .Mounts}}{{if .RW}}{{println .Source}}{{end}}{{end}}' "${objects[@]}")"
      assert_mounts_unused "$mounts" "$@"
    fi
  done
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
  init | status | rebuild)
    "$1"
    ;;
  stack-rm)
    stack_rm "${@:2}"
    ;;
  services-stop)
    services_stop
    ;;
  assert-unused)
    assert_unused "${@:2}"
    ;;
  *)
    printf 'Usage: %s {init|status|rebuild|stack-rm STACK|services-stop|assert-unused DATASET...}\n' "$0" >&2
    exit 1
    ;;
esac
