#!/usr/bin/env bash
set -euo pipefail

dump="${1:?PostgreSQL dump path is required}"
if [[ ! -s "$dump" ]]; then
  printf 'Missing or empty PostgreSQL dump: %s\n' "$dump" >&2
  exit 1
fi

modified=$(stat -L -c %Y -- "$dump")
age=$(($(date +%s) - modified))
if ((age < 0 || age > 21600)); then
  printf 'PostgreSQL dump must be less than six hours old: %s\n' "$dump" >&2
  exit 1
fi

gzip -t -- "$dump"
