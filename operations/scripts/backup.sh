#!/usr/bin/env bash
set -euo pipefail

flock -n -E 75 \
  /run/swarm-zfs-snapshot.lock \
  /usr/local/sbin/swarm-zfs-snapshot

if ! borgmatic repo-info >/dev/null 2>&1; then
  borgmatic repo-create \
    --encryption repokey \
    --make-parent-dirs
fi

borgmatic create
