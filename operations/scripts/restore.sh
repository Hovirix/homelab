#!/usr/bin/env bash
set -euo pipefail

mode="${1:?usage: restore.sh validate-local|local DATASET SNAPSHOT CONFIRM | offsite DATASET ARCHIVE}"
parent='rpool/swarm'
datasets='grafana loki paperless postgres traefik valkey vaultwarden victoriametrics'

validate_dataset() {
  [[ " $datasets " == *" $1 "* ]] || {
    printf 'Unknown persistent dataset: %s\n' "$1" >&2
    exit 2
  }
}

validate_local() {
  local dataset="$1" snapshot="$2" confirm="$3"
  validate_dataset "$dataset"
  [[ $confirm == "$snapshot" ]] || {
    printf 'Confirmation must exactly match snapshot: %s\n' "$snapshot" >&2
    exit 2
  }
  zfs list -H -t snapshot -o name "$parent/$dataset" | awk -v wanted="$snapshot" '$0 == wanted {found=1} END {exit !found}' || {
    printf 'Snapshot does not exist on %s: %s\n' "$parent/$dataset" "$snapshot" >&2
    exit 2
  }
}

case "$mode" in
  validate-local|local)
    [[ $# == 4 ]] || { printf 'usage: restore.sh %s DATASET SNAPSHOT CONFIRM\n' "$mode" >&2; exit 2; }
    validate_local "$2" "$3" "$4"
    if [[ $mode == local ]]; then
      flock -n /run/swarm-zfs-snapshot.lock zfs rollback -r "$3"
    fi
    ;;
  offsite)
    [[ $# == 3 ]] || { printf 'usage: restore.sh offsite DATASET ARCHIVE\n' >&2; exit 2; }
    dataset="$2"
    archive="$3"
    validate_dataset "$dataset"
    borgmatic repo-list --short | awk -v wanted="$archive" '$0 == wanted {found=1} END {exit !found}' || {
      printf 'Archive not found: %s\n' "$archive" >&2
      exit 2
    }
    borgmatic list --archive "$archive" --short | awk -F/ -v wanted="$parent/$dataset" '$0 ~ ("^" wanted "/") {found=1} END {exit !found}' || {
      printf 'Dataset %s is not in archive %s\n' "$parent/$dataset" "$archive" >&2
      exit 2
    }
    staging="rpool/restore/$dataset-$(date -u +%Y-%m-%d_%H-%M-%S)"
    zfs create -p "$staging"
    mountpoint="$(zfs get -H -o value mountpoint "$staging")"
    borgmatic extract --archive "$archive" --path "$parent/$dataset" --destination "$mountpoint" --strip-components 3
    printf 'Borg checksum-verified extraction staged at %s. No service-start check was performed.\n' "$mountpoint"
    printf 'Manual cutover: schedule maintenance, stop the owning stack and dependents, preserve the live dataset, copy staged contents into the live mount, restart dependencies before consumers, and verify application health and data before returning traffic.\n'
    ;;
  *)
    printf 'usage: restore.sh validate-local|local DATASET SNAPSHOT CONFIRM | offsite DATASET ARCHIVE\n' >&2
    exit 2
    ;;
esac
