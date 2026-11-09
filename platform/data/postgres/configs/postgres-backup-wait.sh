#!/usr/bin/env bash
set -euo pipefail

# Only run before a backup.
[[ ${1:-} == pre-backup ]] || exit 0

# Wait up to 5 minutes for PostgreSQL to become ready.
# shellcheck disable=SC2016
if ! timeout 5m bash -c '
  until pg_isready \
    -h "$POSTGRES_HOST" \
    -p "${POSTGRES_PORT:-5432}" \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" >/dev/null 2>&1; do
    sleep 2
  done
'; then
  echo "PostgreSQL did not become ready within 5 minutes." >&2
  exit 1
fi
