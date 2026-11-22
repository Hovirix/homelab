#!/usr/bin/env bash
set -euo pipefail
umask 077

destination="/mnt/swarm"
listing=$(mktemp)
trap 'rm -f -- "$listing"' EXIT

if [[ ! -t 0 || ! -t 1 ]]; then
  printf 'An interactive terminal is required.\n' >&2
  exit 1
fi

if [[ $(findmnt -n -o TARGET --target "$destination") != "$destination" || ! -w "$destination" ]]; then
  printf 'The Swarm volume must be mounted writable at %s.\n' "$destination" >&2
  exit 1
fi

if ! grep -Eq '^numeric_ids:[[:space:]]*true[[:space:]]*$' /etc/borgmatic/config.yaml; then
  printf 'Borgmatic must have numeric_ids: true to preserve ownership.\n' >&2
  exit 1
fi

borgmatic --no-color --verbosity -1 repo-list --match-archives 'sh:*' --json >"$listing"
jq -e 'type == "array" and length == 1 and (.[0].archives | type == "array")' "$listing" >/dev/null
mapfile -t archives < <(jq -r '.[0].archives | sort_by(.time) | reverse | .[] | @base64' "$listing")
if ((${#archives[@]} == 0)); then
  printf 'No Borg archives found.\n' >&2
  exit 1
fi

printf '\nBorg archives — newest first:\n'
for index in "${!archives[@]}"; do
  record=$(printf '%s' "${archives[index]}" | base64 -d)
  name=$(jq -er '.name | select(type == "string" and length > 0)' <<<"$record")
  timestamp=$(jq -er '.time | select(type == "string" and length > 0)' <<<"$record")
  timestamp=$(TZ=UTC0 date -u -d "$timestamp" '+%Y-%m-%d %H:%M UTC')
  printf '%d. %s — %s\n' "$((index + 1))" "$timestamp" "$name"
done

count=${#archives[@]}
while true; do
  read -r -p 'Choose one: ' selection
  if [[ "$selection" =~ ^[1-9][0-9]*$ ]] &&
    ((${#selection} <= ${#count} && 10#$selection <= count)); then
    record=$(printf '%s' "${archives[10#$selection - 1]}" | base64 -d)
    archive=$(jq -er '.name' <<<"$record")
    break
  fi
  printf 'Invalid selection.\n' >&2
done

borgmatic --no-color list --archive "$archive" --short >"$listing"
mapfile -t datasets < <(
  awk -F/ '
    ($1 == "rpool" || $1 == "sources" || $1 == "mnt") && $2 == "swarm" &&
    $3 ~ /^[a-zA-Z0-9][a-zA-Z0-9_-]*$/ {
      print $1 "/" $2 "/" $3
    }
  ' "$listing" | sort -u
)
if ((${#datasets[@]} == 0)); then
  printf 'No supported application datasets found in this archive.\n' >&2
  exit 1
fi

printf '\nChoose a dataset:\n'
printf '1. All datasets\n'
for index in "${!datasets[@]}"; do
  printf '%d. %s\n' "$((index + 2))" "${datasets[index]}"
done
count=$((${#datasets[@]} + 1))
while true; do
  read -r -p 'Choose one: ' selection
  if [[ "$selection" =~ ^[1-9][0-9]*$ ]] &&
    ((${#selection} <= ${#count} && 10#$selection <= count)); then
    if ((10#$selection == 1)); then
      selected=("${datasets[@]}")
    else
      selected=("${datasets[10#$selection - 2]}")
    fi
    break
  fi
  printf 'Invalid selection.\n' >&2
done

check_target() {
  local target="$destination/${1##*/}"
  if [[ -L "$target" || (-e "$target" && ! -d "$target") ]]; then
    printf 'Invalid restore destination: %s\n' "$target" >&2
    exit 1
  fi
}

declare -A targets=()
printf '\nArchive: %s\n' "$archive"
for source in "${selected[@]}"; do
  target="$destination/${source##*/}"
  if [[ -v "targets[$target]" ]]; then
    printf 'Multiple archive paths target %s; select one dataset instead.\n' "$target" >&2
    exit 1
  fi
  targets["$target"]=1
  check_target "$source"
  printf 'Source: %s -> %s\n' "$source" "$target"
done
read -r -p 'Type RESTORE to confirm: ' confirmation
[[ "$confirmation" == "RESTORE" ]] || exit 1

for source in "${selected[@]}"; do
  check_target "$source"
  target="$destination/${source##*/}"
  if ! borgmatic --no-color extract --archive "$archive" --path "$source" \
    --destination "$destination" --strip-components 2 --progress; then
    printf 'Restore failed; keep services stopped. Partial files may remain at %s.\n' "$target" >&2
    exit 1
  fi
  printf 'Restored %s.\n' "$target"
done
