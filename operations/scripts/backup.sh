#!/usr/bin/env bash
set -euo pipefail

host='root@pve.home.hovirix.dev'
ssh_opts=(-o BatchMode=yes -o ConnectTimeout=10)

ssh "${ssh_opts[@]}" "$host" /bin/bash -s <<'REMOTE'
set -euo pipefail

/usr/bin/flock -n -E 75 \
  /run/swarm-zfs-snapshot.lock \
  /usr/local/sbin/swarm-zfs-snapshot

/usr/bin/flock -n -E 75 /run/borgmatic.lock /bin/bash -c '
set -euo pipefail

if ! /usr/bin/borgmatic repo-info >/dev/null 2>&1; then
  /usr/bin/borgmatic repo-create --encryption repokey --make-parent-dirs
fi

/usr/bin/borgmatic create
'
REMOTE
