#!/usr/bin/env bash
set -euo pipefail

host='root@pve.home.hovirix.dev'
parent='rpool/swarm'
ssh_opts=(-o BatchMode=yes -o ConnectTimeout=10)

snapshot_output=$(
	ssh "${ssh_opts[@]}" "$host" /bin/bash -s <<'REMOTE'
set -euo pipefail
set -a
source /etc/restic/restic.env
set +a
restic snapshots --compact
REMOTE
)
[[ -n $snapshot_output ]] || {
	echo 'No Restic snapshots found.'
	exit 1
}

printf '%s\n' "$snapshot_output"
mapfile -t snapshots < <(awk 'length($1) >= 8 && $1 ~ /^[[:xdigit:]]+$/ {print $1}' <<<"$snapshot_output")
((${#snapshots[@]})) || {
	echo 'No Restic snapshots found.'
	exit 1
}
echo
echo 'Select Restic snapshot:'
PS3='Snapshot: '
select snapshot in "${snapshots[@]}"; do
	[[ -n $snapshot ]] && break
	echo 'Invalid selection.'
done

echo
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
echo 'Select dataset data to stage:'
PS3='Dataset: '
select name in "${datasets[@]}"; do
	[[ -n $name ]] && break
	echo 'Invalid selection.'
done

ssh "${ssh_opts[@]}" "$host" /bin/bash -s -- "$snapshot" "$name" <<'REMOTE'
set -euo pipefail

snapshot="$1"
name="$2"
source_path="/rpool/swarm/$name"
staging="$(mktemp -d "/var/tmp/restic-restore-$name.XXXXXX")"

set -a
source /etc/restic/restic.env
set +a

restic restore "$snapshot" --include "$source_path" --target "$staging"

printf '\nStaged restore:\n'
printf '  Restic snapshot: %s\n' "$snapshot"
printf '  Restored data:   %s\n' "$source_path"
printf '  Staging path:    %s%s\n' "$staging" "$source_path"
printf '  Live dataset:    rpool/swarm/%s (/var/mnt/swarm/%s)\n' "$name" "$name"
printf '\nInspect the staging path before performing a separate, manual copy or move.\n'
REMOTE
