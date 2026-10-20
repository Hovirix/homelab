#!/usr/bin/env bash

set -euo pipefail

export PGPASSWORD
PGPASSWORD="$(</run/secrets/postgres_superuser_password)"

authentik_password="$(</run/secrets/postgres_authentik_password)"
grafana_password="$(</run/secrets/postgres_grafana_password)"
paperless_password="$(</run/secrets/postgres_paperless_password)"
vaultwarden_password="$(</run/secrets/postgres_vaultwarden_password)"

if ! timeout 300 bash -c 'until pg_isready --host=postgres --port=5432 --username=postgres >/dev/null 2>&1; do sleep 2; done'; then
  printf 'PostgreSQL did not become ready within five minutes.\n' >&2
  exit 1
fi

psql \
  --host=postgres \
  --port=5432 \
  --username=postgres \
  --dbname=postgres \
  --set=ON_ERROR_STOP=1 \
  --set=authentik_password="$authentik_password" \
  --set=grafana_password="$grafana_password" \
  --set=paperless_password="$paperless_password" \
  --set=vaultwarden_password="$vaultwarden_password" <<'SQL'

SELECT 'CREATE ROLE authentik LOGIN'
WHERE NOT EXISTS (
  SELECT FROM pg_roles WHERE rolname = 'authentik'
)\gexec

SELECT 'CREATE ROLE paperless LOGIN'
WHERE NOT EXISTS (
  SELECT FROM pg_roles WHERE rolname = 'paperless'
)\gexec

SELECT 'CREATE ROLE grafana LOGIN'
WHERE NOT EXISTS (
  SELECT FROM pg_roles WHERE rolname = 'grafana'
)\gexec

SELECT 'CREATE ROLE vaultwarden LOGIN'
WHERE NOT EXISTS (
  SELECT FROM pg_roles WHERE rolname = 'vaultwarden'
)\gexec

ALTER ROLE authentik PASSWORD :'authentik_password';
ALTER ROLE grafana PASSWORD :'grafana_password';
ALTER ROLE paperless PASSWORD :'paperless_password';
ALTER ROLE vaultwarden PASSWORD :'vaultwarden_password';

SELECT 'CREATE DATABASE authentik OWNER authentik'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'authentik'
)\gexec

SELECT 'CREATE DATABASE paperless OWNER paperless'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'paperless'
)\gexec

SELECT 'CREATE DATABASE grafana OWNER grafana'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'grafana'
)\gexec

SELECT 'CREATE DATABASE vaultwarden OWNER vaultwarden'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'vaultwarden'
)\gexec
SQL
