#!/usr/bin/env bash
set -euo pipefail

if [[ ! -t 0 ]]; then
  printf 'An interactive terminal is required.\n' >&2
  exit 1
fi

incus exec incus:backup -- rsync --version >/dev/null

listing=$(incus storage volume snapshot list incus:data swarm --format=json)
snapshots_json=$(jq -r 'sort_by(.created_at) | reverse | .[].name' <<<"$listing")

if [[ -z "$snapshots_json" ]]; then
  printf 'No local Swarm snapshots found.\n' >&2
  exit 1
fi

mapfile -t snapshots <<<"$snapshots_json"
mapfile -t timestamps < <(jq -r 'sort_by(.created_at) | reverse | .[].created_at' <<<"$listing")

printf '\nChoose a snapshot:\n'

for index in "${!snapshots[@]}"; do
  snapshot_dates[index]=$(date -u -d "${timestamps[index]}" '+%Y-%m-%d %H:%M UTC')
  printf '%d. %s — %s\n' "$((index + 1))" "${snapshot_dates[index]}" "${snapshots[index]##*/}"
done

count=${#snapshots[@]}

while true; do
  read -r -p 'Choose one: ' selection

  if [[ "$selection" =~ ^[1-9][0-9]*$ ]] &&
    ((${#selection} <= ${#count} && 10#$selection <= count)); then
    snapshot=${snapshots[10#$selection - 1]##*/}
    snapshot_date=${snapshot_dates[10#$selection - 1]}
    break
  fi

  printf 'Invalid selection.\n' >&2
done

temporary="restore-$(date +%s)-$RANDOM"
source="/mnt/$temporary"
copied=false
attached=false

cleanup() {
  local result=$?
  trap - EXIT

  if [[ "$attached" == true ]]; then
    if ! incus config device remove incus:backup "$temporary" >/dev/null; then
      printf 'Cleanup failed: detach device %s before deleting its temporary volume.\n' "$temporary" >&2
      exit 1
    fi
  fi

  if [[ "$copied" == true ]]; then
    if ! incus storage volume delete incus:data "$temporary" >/dev/null; then
      printf 'Cleanup failed: temporary volume data/%s remains.\n' "$temporary" >&2
      result=1
    else
      printf '✓ Temporary volume removed\n'
    fi
  fi

  exit "$result"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

incus storage volume copy "incus:data/swarm/$snapshot" "incus:data/$temporary" --quiet >/dev/null
copied=true

incus config device add incus:backup "$temporary" disk pool=data source="$temporary" path="$source" readonly=true >/dev/null
attached=true

listing=$(incus exec incus:backup -- find "$source" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')

if [[ -z "$listing" ]]; then
  printf 'No application directories in this snapshot.\n' >&2
  exit 1
fi

mapfile -t apps < <(printf '%s\n' "$listing" | LC_ALL=C sort)

printf '\nChoose an application:\n'

for index in "${!apps[@]}"; do
  printf '%d. %s\n' "$((index + 1))" "${apps[index]}"
done

count=${#apps[@]}

while true; do
  read -r -p 'Choose one: ' selection

  if [[ "$selection" =~ ^[1-9][0-9]*$ ]] &&
    ((${#selection} <= ${#count} && 10#$selection <= count)); then
    app=${apps[10#$selection - 1]}
    break
  fi

  printf 'Invalid selection.\n' >&2
done

if [[ ! "$app" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
  printf 'Unsupported directory name.\n' >&2
  exit 1
fi

printf '\nRestore:  %s\nSnapshot: %s — %s\nTarget:   /mnt/swarm/%s\n\n' "$app" "$snapshot_date" "$snapshot" "$app"
printf 'Existing files will be overwritten. Destination-only files remain.\n'

read -r -p 'Type RESTORE to confirm: ' confirmation

if [[ "$confirmation" != RESTORE ]]; then
  exit 0
fi

# shellcheck disable=SC2016
incus exec incus:backup -- bash -euo pipefail -c '
    source=$1
    app=$2

    [[ $(findmnt -n -o TARGET --target "$source") == "$source" ]]
    [[ $(findmnt -n -o TARGET --target /mnt/swarm) == /mnt/swarm ]]
    [[ -d "$source/$app" && ! -L "$source/$app" ]]
    [[ ! -L "/mnt/swarm/$app" ]]
    [[ ! -e "/mnt/swarm/$app" || -d "/mnt/swarm/$app" ]]

    rsync -aHAX --checksum --numeric-ids -- "$source/$app/" "/mnt/swarm/$app/"
' bash "$source" "$app"

printf '\n✓ %s restored\n' "$app"
