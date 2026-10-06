#!/usr/bin/env bash
set -euo pipefail

ssh \
  -o BatchMode=yes \
  -o ConnectTimeout=10 \
  root@pve.home.hovirix.dev \
  '/usr/bin/flock -n -E 75 /run/backup.lock /bin/bash -s' <<'REMOTE'
set -euo pipefail

dataset='rpool/swarm'
snapshot_name="manual-$(date -u +%Y-%m-%d_%H-%M-%S)"
mountpoint="$(zfs get -H -o value mountpoint "$dataset")"

# Local backup
zfs snapshot -r "$dataset@$snapshot_name"

# Off-site backup
set -a
source /etc/restic/restic.env
set +a

restic backup "$mountpoint"
REMOTE
