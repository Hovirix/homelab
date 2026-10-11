#!/usr/bin/env bash
set -euo pipefail

mode="${1:?usage: restore.sh local|offsite|cutover <dataset> <staging>}"
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

confirm_destructive() {
  local expected="$1" reply
  read -r -p "Type '$expected' to confirm: " reply
  [[ $reply == "$expected" ]] || {
    printf 'Aborted.\n' >&2
    exit 1
  }
}

# Borg verifies archive checksums during extract, so a successful extract
# already proves archive integrity; here we prove the staged copy is usable.
verify_staged() {
  local mountpoint="$1" staged_dataset="$2"
  [[ -n $(ls -A "$mountpoint") ]] || {
    printf 'Staged data is empty: %s\n' "$mountpoint" >&2
    return 1
  }
  if [[ $staged_dataset == postgres ]]; then
    [[ -f $mountpoint/PG_VERSION ]] || {
      printf 'Staged postgres data has no PG_VERSION: %s\n' "$mountpoint" >&2
      return 1
    }
  fi
}

restore_local() {
  select_dataset

  mapfile -t snapshots < <(
    zfs list -H -t snapshot -o name -S creation "$parent/$dataset"
  )

  pick 'Select snapshot:' snapshot "${snapshots[@]}"

  # Snapshots are listed newest-first, so entries before the target are
  # newer and will be destroyed by the rollback.
  newer=()
  for s in "${snapshots[@]}"; do
    [[ $s == "$snapshot" ]] && break
    newer+=("$s")
  done

  printf 'DANGER: rollback of %s to %s destroys all data after that snapshot' "$parent/$dataset" "$snapshot"
  if ((${#newer[@]})); then
    printf ' including %d newer snapshot(s):\n' "${#newer[@]}"
    printf '  %s\n' "${newer[@]}"
  else
    printf '.\n'
  fi
  confirm_destructive "$snapshot"

  flock -n /run/swarm-zfs-snapshot.lock zfs rollback -r "$snapshot"
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

  verify_staged "$mountpoint" "$dataset"

  printf 'Staged restore verified: %s\n' "$mountpoint"
  printf 'Cut over with: task restore:cutover DATASET=%s STAGING=%s\n' "$dataset" "$staging"
}

cutover() {
  local live staging_mp live_mp
  dataset="${1:?usage: restore.sh cutover <dataset> <staging>}"
  staging="${2:?usage: restore.sh cutover <dataset> <staging>}"
  live="$parent/$dataset"

  # Read-only lookups first so a bad DATASET/STAGING fails before any mutation.
  staging_mp="$(zfs get -H -o value mountpoint "$staging")"
  live_mp="$(zfs get -H -o value mountpoint "$live")"

  verify_staged "$staging_mp" "$dataset"

  printf 'DANGER: cutover replaces live data in %s with staged data from %s\n' "$live" "$staging"
  printf 'A pre-cutover snapshot of %s will be taken first.\n' "$live"
  confirm_destructive "$dataset"

  zfs snapshot "$live@pre-cutover-$(date -u +%Y-%m-%d_%H-%M-%S)"
  rsync -a --delete "$staging_mp/" "$live_mp/"

  printf 'Cut over %s to %s. Redeploy the stack, then verify services.\n' "$staging" "$live"
}

case "$mode" in
  local)
    restore_local
    ;;
  offsite)
    restore_offsite
    ;;
  cutover)
    shift
    cutover "$@"
    ;;
  *)
    echo "usage: $0 local|offsite|cutover <dataset> <staging>" >&2
    exit 2
    ;;
esac
