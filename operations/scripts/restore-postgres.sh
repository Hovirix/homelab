#!/usr/bin/env bash
set -euo pipefail
umask 077

: "${DOCKER_HOST:?required}"
[[ -t 0 ]] || {
  printf 'An interactive terminal is required.\n' >&2
  exit 1
}

node=$(docker service ps --filter desired-state=running --format '{{.Node}}' postgres_backup)
[[ -n $node && $node != *$'\n'* ]] || {
  printf 'Expected exactly one PostgreSQL backup task.\n' >&2
  exit 1
}
read -r -a hosts <<<"${MANAGER_HOSTS:?required}"
endpoint=""
for host in "${hosts[@]}"; do
  hostname=${host#ssh://}
  hostname=${hostname##*@}
  hostname=${hostname%%:*}
  if [[ $hostname == "$node" || ${hostname%%.*} == "$node" ]]; then
    endpoint=$host
    break
  fi
done
[[ -n $endpoint ]] || {
  printf 'No configured SSH endpoint for node %s.\n' "$node" >&2
  exit 1
}
export DOCKER_HOST="$endpoint"
container=$(docker ps --filter label=com.docker.swarm.service.name=postgres_backup --format '{{.ID}}')
[[ -n $container && $container != *$'\n'* ]] || {
  printf 'Expected exactly one running PostgreSQL backup container.\n' >&2
  exit 1
}

listing=$(docker exec -e TZ=UTC "$container" find /backups -type f -name '*.sql.gz' \
  -printf '%T@\t%D:%i\t%TY-%Tm-%Td %TH:%TM\t%p\n' |
  sort -t $'\t' -k1,1nr -k4,4)
[[ -n $listing ]] || { printf 'No SQL dumps found.\n' >&2; exit 1; }
dumps=()
declare -A seen=()
printf '\nSelect a backup (UTC):\n\n'
while IFS=$'\t' read -r _ identity stamp path; do
  [[ ! ${seen[$identity]+exists} ]] || continue
  seen[$identity]=1
  dumps+=("$path")
  printf '  %d) %s\n' "${#dumps[@]}" "$stamp"
done <<<"$listing"
count=${#dumps[@]}
printf '\n'
while true; do
  read -r -p 'Select a number (Enter to cancel): ' selection || exit 0
  [[ -n $selection ]] || exit 0
  if [[ $selection =~ ^[1-9][0-9]*$ ]] &&
    ((${#selection} <= ${#count} && 10#$selection <= count)); then
    dump=${dumps[10#$selection - 1]}
    break
  fi
  printf 'Invalid selection. Enter a number from 1 to %s.\n' "$count" >&2
done

printf '\nSource:  %s\n' "$dump"
printf 'Target:  postgres\n'
printf 'Action:  Replace all non-template databases and application roles\n\n'
read -r -p 'Type RESTORE to confirm: ' confirmation || exit 0
[[ $confirmation == RESTORE ]] || exit 0
printf '\n'

if ! docker exec -i "$container" bash -euo pipefail -s -- "$dump" <<'BASH'
umask 077
sql=$(mktemp)
trap '
  status=$?
  if ((status)); then
    printf "failed\n" >&2
    [[ ! -f $sql.log ]] || cat "$sql.log" >&2
  fi
  rm -f -- "$sql" "$sql.log" "$sql.filtered"
' EXIT
printf '[1/3] Validating backup... '
gzip -dc -- "$1" > "$sql"
grep -q '^-- PostgreSQL database cluster dump$' "$sql"
grep -q '^-- PostgreSQL database cluster dump complete$' "$sql"
# Keep the live administrator usable, including across dump \connect commands.
sed -i '/^CREATE ROLE postgres;$/d; /^ALTER ROLE postgres /d' "$sql"
export PGPASSWORD
PGPASSWORD=$(cat /run/secrets/postgres_superuser_password)
export PGHOST=postgres PGUSER=postgres
# OID 10 is the pinned bootstrap superuser, which may not be named postgres.
bootstrap=$(psql -XAt --dbname=template1 --set=ON_ERROR_STOP=1 \
  --command="SELECT format('CREATE ROLE %I;', rolname) FROM pg_roles WHERE oid = 10" 2>"$sql.log")
grep -Fvx -- "$bootstrap" "$sql" > "$sql.filtered"
mv -- "$sql.filtered" "$sql"
printf 'done\n[2/3] Removing existing databases and roles... '
psql -X --dbname=template1 --set=ON_ERROR_STOP=1 > "$sql.log" 2>&1 <<'SQL'
SELECT format('DROP DATABASE %I WITH (FORCE)', datname)
FROM pg_database WHERE NOT datistemplate
\gexec
SELECT format('DROP ROLE %I', rolname)
FROM pg_roles WHERE oid <> 10 AND rolname <> current_user AND rolname !~ '^pg_'
\gexec
CREATE DATABASE postgres OWNER postgres TEMPLATE template0;
SQL
printf 'done\n[3/3] Restoring backup... '
psql -X --dbname=postgres --set=ON_ERROR_STOP=1 --file="$sql" > "$sql.log" 2>&1
printf 'done\n'
BASH
then
  printf 'Restore failed.\n' >&2
  exit 1
fi
printf '\nRestore complete.\n'
