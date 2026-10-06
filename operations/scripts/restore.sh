#!/usr/bin/env bash
set -euo pipefail

mode="${1:?usage: restore.sh local|offsite}"
parent='rpool/swarm'

select_dataset() {
  mapfile -t datasets < <(
    zfs list -H -o name -d 1 "$parent" |
      sed -n "s#^$parent/##p" |
      sort
  )

  echo 'Select dataset:'
  select dataset in "${datasets[@]}"; do
    [[ -n $dataset ]] && return
  done
}

restore_local() {
  select_dataset

  mapfile -t snapshots < <(
    zfs list -H -t snapshot -o name -S creation "$parent/$dataset"
  )

  echo 'Select snapshot:'
  select snapshot in "${snapshots[@]}"; do
    [[ -n $snapshot ]] && break
  done

  flock -n /run/swarm-zfs-snapshot.lock zfs rollback "$snapshot"
}

restore_offsite() {
  local restore_parent='rpool/restore' staging mountpoint

  mapfile -t archives < <(borgmatic repo-list --short)

  echo 'Select archive:'
  select archive in "${archives[@]}"; do
    [[ -n $archive ]] && break
  done

  mapfile -t datasets < <(
    borgmatic list --archive "$archive" --short |
      awk -F/ '
        $1 == "rpool" && $2 == "swarm" && NF >= 3 {
          print $3
        }
      ' |
      sort -u
  )

  echo 'Select dataset:'
  select dataset in "${datasets[@]}"; do
    [[ -n $dataset ]] && break
  done

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
