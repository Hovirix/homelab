#!/usr/bin/env bash
set -euo pipefail

dump="${1:?ERROR: PostgreSQL dump path is required}"
if [[ ! -s "$dump" ]]; then
  printf 'ERROR: PostgreSQL dump missing or empty: %s\n' "$dump" >&2
  exit 1
fi

if ! modified=$(stat -L -c %Y -- "$dump"); then
  printf 'ERROR: PostgreSQL dump timestamp cannot be read: %s\n' "$dump" >&2
  exit 1
fi
age=$(($(date +%s) - modified))
if ((age < 0 || age > 21600)); then
  printf 'WARNING: PostgreSQL dump is older than six hours. %s\n' "$dump" >&2
fi

if ! gzip -t -- "$dump"; then
  printf 'ERROR: PostgreSQL dump gzip integrity check failed: %s\n' "$dump" >&2
  exit 1
fi
