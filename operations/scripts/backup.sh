#!/usr/bin/env bash
set -euo pipefail

host='root@pve1.home.hovirix.dev'

if ssh \
  -o BatchMode=yes \
  -o ConnectTimeout=10 \
  "$host" \
  '/usr/bin/flock -n -E 75 /run/swarm-zfs-snapshot.lock /usr/local/sbin/swarm-zfs-snapshot'; then
  printf 'Backup completed successfully.\n'
else
  status=$?

  if ((status == 75)); then
    printf 'Backup skipped: snapshot operation already running.\n' >&2
  else
    printf 'Backup failed.\n' >&2
  fi

  exit "$status"
fi
