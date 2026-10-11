#!/usr/bin/env bash
set -euo pipefail

# Manual entrypoint for task backup. Shares the timer implementation so both
# paths snapshot, dump, and archive identically.
exec flock -n -E 75 /run/offsite-backup.lock /usr/local/sbin/offsite-backup
