#!/usr/bin/env bash
set -euo pipefail

: "${DOCKER_HOST:?required}"

host='root@pve.home.hovirix.dev'
parent='rpool/swarm'
lock='/run/swarm-zfs-snapshot.lock'
ssh_opts=(-o BatchMode=yes -o ConnectTimeout=10)

dataset_output=$(
  ssh "${ssh_opts[@]}" "$host" /bin/bash -s -- "$parent" <<'REMOTE'
set -euo pipefail

parent="$1"
zfs list -H -o name -d 1 "$parent" | sed -n "s#^$parent/##p" | sort
REMOTE
)
[[ -n $dataset_output ]] || {
  echo 'No Swarm datasets found.'
  exit 1
}

mapfile -t datasets <<<"$dataset_output"
echo 'Select dataset:'
PS3='Dataset: '
select name in "${datasets[@]}"; do
  [[ -n $name ]] && break
  echo 'Invalid selection.'
done

dataset="$parent/$name"
path="/var/mnt/swarm/$name"

snapshot_output=$(
  ssh "${ssh_opts[@]}" "$host" /bin/bash -s -- "$dataset" <<'REMOTE'
set -euo pipefail

dataset="$1"
zfs list -H -t snapshot -o name -S creation "$dataset" | grep -F "$dataset@" || true
REMOTE
)
[[ -n $snapshot_output ]] || {
  echo "No snapshots found for $dataset."
  exit 1
}

mapfile -t snapshots <<<"$snapshot_output"
echo
echo "Select snapshot for $dataset:"
PS3='Snapshot: '
select snapshot in "${snapshots[@]}"; do
  [[ -n $snapshot ]] && break
  echo 'Invalid selection.'
done

service_output="$(docker service ls --quiet)"
services=()
replicas=()

while IFS= read -r service; do
  [[ -n $service ]] || continue

  mounts="$(docker service inspect --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{if eq .Type "bind"}}{{.Source}}{{"\n"}}{{end}}{{end}}' "$service")"
  while IFS= read -r mount; do
    [[ $mount == "$path" || $mount == "$path/"* ]] || continue

    replica_count="$(docker service inspect --format '{{if .Spec.Mode.Replicated}}{{.Spec.Mode.Replicated.Replicas}}{{end}}' "$service")"
    [[ -n $replica_count ]] || {
      printf 'Cannot safely scale matching service %s; it is not replicated.\n' "$service" >&2
      exit 1
    }

    services+=("$service")
    replicas+=("$replica_count")
    break
  done <<<"$mounts"
done <<<"$service_output"

echo
echo 'Restore summary:'
echo "  Dataset:  $dataset"
echo "  Snapshot: $snapshot"
if ((${#services[@]})); then
  echo '  Affected services:'
  for i in "${!services[@]}"; do
    printf '    %s (replicas: %s)\n' "${services[$i]}" "${replicas[$i]}"
  done
else
  echo '  Affected services: none'
fi

echo
echo 'WARNING: data written after this snapshot will be lost.'
echo 'Newer snapshots are not deleted automatically; rollback will fail if they exist.'
read -r -p 'Type "restore" to continue: ' confirmation
[[ $confirmation == restore ]] || {
  echo 'Restore cancelled.'
  exit 1
}

restore_services() {
  local restore_status=0 i

  for i in "${!services[@]}"; do
    docker service update --detach=true --replicas "${replicas[$i]}" "${services[$i]}" >/dev/null || restore_status=1
  done

  return "$restore_status"
}

on_exit() {
  local status="$?"
  trap - EXIT
  restore_services || status=1
  exit "$status"
}

if ((${#services[@]})); then
  trap on_exit EXIT

  for service in "${services[@]}"; do
    docker service update --detach=true --replicas 0 "$service" >/dev/null
  done

  for service in "${services[@]}"; do
    stopped=false

    for ((attempt = 0; attempt < 120; attempt++)); do
      states="$(docker service ps --format '{{.CurrentState}}' "$service")"
      if ! grep -Eq '^(New|Pending|Assigned|Accepted|Preparing|Ready|Starting|Running)' <<<"$states"; then
        stopped=true
        break
      fi
      sleep 1
    done

    [[ $stopped == true ]] || {
      printf 'Timed out waiting for service %s to stop.\n' "$service" >&2
      exit 1
    }
  done
fi

ssh "${ssh_opts[@]}" "$host" /bin/bash -s -- "$snapshot" "$lock" <<'REMOTE'
set -euo pipefail

snapshot="$1"
lock="$2"
flock -n "$lock" zfs rollback "$snapshot"
REMOTE

if ((${#services[@]})); then
  restore_services
  trap - EXIT
fi

echo "Restored $dataset from $snapshot."
