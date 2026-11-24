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

listing=$(docker exec "$container" find /backups -type f -name '*.sql.gz' | sort -r)
[[ -n $listing ]] || { printf 'No SQL dumps found.\n' >&2; exit 1; }
mapfile -t dumps <<<"$listing"
printf '\nChoose a PostgreSQL cluster dump:\n'
for index in "${!dumps[@]}"; do
  printf '%d. %s\n' "$((index + 1))" "${dumps[index]}"
done
count=${#dumps[@]}
while true; do
  read -r -p 'Choose one: ' selection
  if [[ $selection =~ ^[1-9][0-9]*$ ]] &&
    ((${#selection} <= ${#count} && 10#$selection <= count)); then
    dump=${dumps[10#$selection - 1]}
    break
  fi
  printf 'Invalid selection.\n' >&2
done

printf '\nRestore ALL databases from %s using the PostgreSQL backup container.\n' "$dump"
printf 'Stop database clients and suspend SQL dump scheduling; keep PostgreSQL and its backup container running.\n'
printf 'This imports SQL, not a clean replacement. Existing roles or objects can cause errors.\n'
printf 'Failure can leave a partial import. No automatic rollback is performed.\n'
read -r -p 'Type RESTORE to confirm: ' confirmation
[[ $confirmation == RESTORE ]] || exit 0

# shellcheck disable=SC2016
if ! docker exec "$container" bash -euo pipefail -c '
    gzip -t -- "$1"
    export PGPASSWORD
    PGPASSWORD=$(cat /run/secrets/postgres_superuser_password)
    gzip -dc -- "$1" | psql -X --host=postgres --username=postgres --dbname=postgres --set=ON_ERROR_STOP=1
  ' bash "$dump"; then
  printf 'SQL import failed. Keep applications stopped and inspect the database before retrying.\n' >&2
  exit 1
fi
printf 'SQL import complete. Verify databases before restarting applications.\n'
