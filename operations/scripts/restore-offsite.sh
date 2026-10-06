#!/usr/bin/env bash
set -euo pipefail

host='root@pve.home.hovirix.dev'
lock='/run/borgmatic.lock'
ssh_opts=(-o BatchMode=yes -o ConnectTimeout=10)

archive_output=$(
  ssh "${ssh_opts[@]}" "$host" /bin/bash -s -- "$lock" <<'REMOTE'
set -euo pipefail

lock="$1"
flock -n -E 75 "$lock" borgmatic repo-list --short
REMOTE
)
[[ -n $archive_output ]] || {
  echo 'No Borg archives found.'
  exit 1
}

mapfile -t archives <<<"$archive_output"
echo 'Select Borg archive:'
PS3='Archive: '
select archive in "${archives[@]}"; do
  [[ -n $archive ]] && break
  echo 'Invalid selection.'
done

dataset_output=$(
  ssh "${ssh_opts[@]}" "$host" /bin/bash -s -- "$lock" "$archive" <<'REMOTE'
set -euo pipefail

lock="$1"
archive="$2"

flock -n -E 75 "$lock" borgmatic list --archive "$archive" --short |
  awk -F/ '$1 == "rpool" && $2 == "swarm" && NF >= 3 { print $3 }' |
  sort -u
REMOTE
)
[[ -n $dataset_output ]] || {
  echo "No Swarm dataset data found in $archive."
  exit 1
}

mapfile -t datasets <<<"$dataset_output"
echo
echo 'Select dataset data to stage:'
PS3='Dataset: '
select name in "${datasets[@]}"; do
  [[ -n $name ]] && break
  echo 'Invalid selection.'
done

ssh "${ssh_opts[@]}" "$host" /bin/bash -s -- "$lock" "$archive" "$name" <<'REMOTE'
set -euo pipefail

lock="$1"
archive="$2"
name="$3"
staging_root='/rpool/restore'
staging="$staging_root/$name-$(date -u +%Y-%m-%d_%H-%M-%S)"

install -d -m 0700 "$staging_root"
mkdir -m 0700 "$staging"

flock -n -E 75 "$lock" borgmatic extract \
  --archive "$archive" \
  --path "rpool/swarm/$name" \
  --destination "$staging" \
  --strip-components 3

printf '\nStaged restore:\n'
printf '  Borg archive:  %s\n' "$archive"
printf '  Restored data: /rpool/swarm/%s\n' "$name"
printf '  Staging path:  %s\n' "$staging"
printf '  Live dataset:  rpool/swarm/%s (/var/mnt/swarm/%s)\n' "$name" "$name"
printf '\nInspect the staging path before performing a separate, manual copy or move.\n'
REMOTE
