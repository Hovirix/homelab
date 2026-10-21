#!/usr/bin/env bash
set -euo pipefail

[[ ${1:-} == pre-backup ]] || exit 0

until pg_isready --host="$POSTGRES_HOST" --port="${POSTGRES_PORT:-5432}" \
  --username="$POSTGRES_USER" --dbname="$POSTGRES_DB" >/dev/null 2>&1; do
  sleep 2
done
