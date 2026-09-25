#!/usr/bin/env bash

set -euo pipefail

export PGPASSWORD
PGPASSWORD="$(</run/secrets/postgres_superuser_password)"

authentik_password="$(</run/secrets/postgres_authentik_password)"
paperless_password="$(</run/secrets/postgres_paperless_password)"

deadline=$((SECONDS + 300))

until pg_isready \
  --host=postgres \
  --port=5432 \
  --username=postgres \
  >/dev/null 2>&1; do
  if ((SECONDS >= deadline)); then
    printf 'PostgreSQL did not become ready within five minutes.\n' >&2
    exit 1
  fi

  sleep 2
done

psql \
  --host=postgres \
  --port=5432 \
  --username=postgres \
  --dbname=postgres \
  --set=ON_ERROR_STOP=1 \
  --set=authentik_password="$authentik_password" \
  --set=paperless_password="$paperless_password" <<'SQL'

SELECT 'CREATE ROLE authentik LOGIN'
WHERE NOT EXISTS (
  SELECT FROM pg_roles WHERE rolname = 'authentik'
)\gexec

SELECT 'CREATE ROLE paperless LOGIN'
WHERE NOT EXISTS (
  SELECT FROM pg_roles WHERE rolname = 'paperless'
)\gexec

ALTER ROLE authentik PASSWORD :'authentik_password';
ALTER ROLE paperless PASSWORD :'paperless_password';

SELECT 'CREATE DATABASE authentik OWNER authentik'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'authentik'
)\gexec

SELECT 'CREATE DATABASE paperless OWNER paperless'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'paperless'
)\gexec
SQL
