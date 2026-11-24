#!/usr/bin/env bash
set -euo pipefail

PASSWORD_FILE="/etc/borgmatic/storagebox-password"
STORAGE_BOX="u683062-sub1@u683062.your-storagebox.de"
WARNING_THRESHOLD=80

if ! usage=$(
  sshpass -f "$PASSWORD_FILE" ssh \
    -p 23 \
    -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=10 \
    -o ServerAliveInterval=10 \
    -o ServerAliveCountMax=3 \
    "$STORAGE_BOX" df -m
); then
  echo "WARNING: Storage Box capacity check failed"
  exit 0
fi

if ! capacity=$(awk '
  NR > 1 && $4 ~ /^[0-9]+$/ && $5 ~ /^[0-9]+%$/ {
    used = $5 + 0

    if (!found || used > max_used) {
      max_used = used
      available = $4
    }

    found = 1
  }

  END {
    if (!found) exit 1
    printf "%d %d\n", max_used, available
  }
' <<<"$usage"); then
  echo "WARNING: Storage Box capacity output was not recognized"
  exit 0
fi

read -r used_percent available_mib <<<"$capacity"

if ((used_percent >= WARNING_THRESHOLD)); then
  printf 'WARNING: '
fi

printf 'Storage Box capacity: used_percent=%s available_mib=%s\n' \
  "$used_percent" "$available_mib"
