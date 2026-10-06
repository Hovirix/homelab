#!/usr/bin/env bash
set -euo pipefail

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

services=$(
	ssh "${ssh_opts[@]}" "$host" /bin/bash -s -- "$path" <<'REMOTE'
set -euo pipefail

path="$1"
while IFS= read -r service; do
  mounts="$(docker service inspect --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{if eq .Type "bind"}}{{.Source}}{{"\n"}}{{end}}{{end}}' "$service")"
  while IFS= read -r mount; do
    [[ $mount == "$path" || $mount == "$path/"* ]] || continue
    replicas="$(docker service inspect --format '{{if .Spec.Mode.Replicated}}{{.Spec.Mode.Replicated.Replicas}}{{end}}' "$service")"
    [[ -n $replicas ]] || {
      printf 'Cannot safely scale matching service %s; it is not replicated.\n' "$service" >&2
      exit 1
    }
    printf '%s\t%s\n' "$service" "$replicas"
    break
  done <<<"$mounts"
done < <(docker service ls --quiet)
REMOTE
)

echo
echo 'Restore summary:'
echo "  Dataset:  $dataset"
echo "  Snapshot: $snapshot"
if [[ -n $services ]]; then
	echo '  Affected services:'
	while IFS=$'\t' read -r service replicas; do
		printf '    %s (replicas: %s)\n' "$service" "$replicas"
	done <<<"$services"
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

ssh "${ssh_opts[@]}" "$host" /bin/bash -s -- "$snapshot" "$lock" "$services" <<'REMOTE'
set -euo pipefail

snapshot="$1"
lock="$2"
services=()
replicas=()

while IFS=$'\t' read -r svc rep; do
  [[ -n $svc ]] || continue
  services+=("$svc")
  replicas+=("$rep")
done <<<"$3"

restore_services() {
  local status="$?" restore_status=0 i
  trap - EXIT
  for i in "${!services[@]}"; do
    docker service update --replicas "${replicas[$i]}" "${services[$i]}" || restore_status=1
  done
  (( status == 0 && restore_status == 0 )) || exit 1
}

if ((${#services[@]})); then
  trap restore_services EXIT
  for service in "${services[@]}"; do
    docker service update --replicas 0 "$service"
  done
  for service in "${services[@]}"; do
    while docker service ps --format '{{.CurrentState}}' "$service" | grep -q '^Running'; do
      sleep 1
    done
  done
fi

flock -n "$lock" zfs rollback "$snapshot"
REMOTE

echo "Restored $dataset from $snapshot."
