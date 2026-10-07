#!/usr/bin/env bash
set -euo pipefail

mode="${1:?usage: restore.sh local|offsite}"
parent='rpool/swarm'
dataset=""
snapshot=""
archive=""

select_dataset() {
  mapfile -t datasets < <(
    zfs list -H -o name -d 1 "$parent" |
      sed -n "s#^$parent/##p" |
      sort
  )

  pick 'Select dataset:' dataset "${datasets[@]}"
}

pick() {
  local prompt="$1" var="$2"
  shift 2

  echo "$prompt"
  select choice in "$@"; do
    [[ -n $choice ]] && break
  done
  printf -v "$var" '%s' "$choice"
}

restore_local() {
  select_dataset

  mapfile -t snapshots < <(
    zfs list -H -t snapshot -o name -S creation "$parent/$dataset"
  )

  pick 'Select snapshot:' snapshot "${snapshots[@]}"

  flock -n /run/swarm-zfs-snapshot.lock zfs rollback "$snapshot"
}

restore_offsite() {
  local restore_parent='rpool/restore' staging mountpoint

  mapfile -t archives < <(borgmatic repo-list --short)

  pick 'Select archive:' archive "${archives[@]}"

  mapfile -t datasets < <(
    borgmatic list --archive "$archive" --short |
      awk -F/ '
        $1 == "rpool" && $2 == "swarm" && NF >= 3 {
          print $3
        }
      ' |
      sort -u
  )

  pick 'Select dataset:' dataset "${datasets[@]}"

  staging="$restore_parent/$dataset-$(date -u +%Y-%m-%d_%H-%M-%S)"
  zfs create -p "$staging"
  mountpoint="$(zfs get -H -o value mountpoint "$staging")"

  borgmatic extract \
    --archive "$archive" \
    --path "$parent/$dataset" \
    --destination "$mountpoint" \
    --strip-components 3

  printf 'Staged restore: %s\n' "$mountpoint"
}

case "$mode" in
  local)
    restore_local
    ;;
  offsite)
    restore_offsite
    ;;
  *)
    echo "usage: $0 local|offsite" >&2
    exit 2
    ;;
esac
