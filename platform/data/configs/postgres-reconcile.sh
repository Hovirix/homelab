#!/usr/bin/env bash

set -euo pipefail

postgres_password_file=/run/secrets/data_postgres_superuser_password
authentik_password_file=/run/secrets/data_postgres_authentik_password

export PGPASSWORD
PGPASSWORD="$(<"$postgres_password_file")"

until pg_isready --host=postgres --port=5432 --username=postgres >/dev/null 2>&1; do
  sleep 2
done

psql --host=postgres --username=postgres --dbname=postgres \
  --set=authentik_password="$(<"$authentik_password_file")" <<'SQL'
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authentik') THEN
    CREATE ROLE authentik LOGIN;
  END IF;
END
$$;

ALTER ROLE authentik WITH PASSWORD :'authentik_password';

SELECT 'CREATE DATABASE authentik OWNER authentik'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'authentik')\gexec

ALTER DATABASE authentik OWNER TO authentik;
GRANT ALL PRIVILEGES ON DATABASE authentik TO authentik;
SQL
