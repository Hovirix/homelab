#!/usr/bin/env bash
set -euo pipefail

section() { printf '\n  \033[1m%s\033[0m\n' "$1"; }
ok() { printf '    \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '    \033[33m⚠\033[0m %s\n' "$1"; }
err() { printf '    \033[31m✗\033[0m %s\n' "$1"; }

failed=0
failed_services=()

section 'Nodes'

while IFS='|' read -r name status availability manager; do
  label="$name ($status, $availability"

  [[ -n $manager ]] && label+=", $manager"

  label+=")"

  if [[ $status != "Ready" ]]; then
    err "$label"
    failed=1
  elif [[ $availability != "Active" ]]; then
    warn "$label"
  else
    ok "$label"
  fi
done < <(
  docker node ls \
    --format '{{.Hostname}}|{{.Status}}|{{.Availability}}|{{.ManagerStatus}}'
)

section 'Services'

while IFS='|' read -r id name replicas; do
  replicas="${replicas%% (*}"

  running="${replicas%%/*}"
  desired="${replicas#*/}"

  [[ $desired -eq 0 ]] && continue

  if ((running < desired)); then
    err "$name $running/$desired"
    failed_services+=("$id")
    failed=1
  elif ((running > desired)); then
    warn "$name $running/$desired"
  else
    ok "$name $running/$desired"
  fi
done < <(
  docker service ls \
    --format '{{.ID}}|{{.Name}}|{{.Replicas}}'
)

if ((${#failed_services[@]} > 0)); then
  section 'Failed Tasks'

  for service in "${failed_services[@]}"; do
    while IFS='|' read -r name node state error; do
      [[ -z $error ]] && continue
      [[ $state == *"Complete"* ]] && continue

      err "$name — $error ($node)"
    done < <(
      docker service ps "$service" \
        --no-trunc \
        --filter "desired-state=running" \
        --format '{{.Name}}|{{.Node}}|{{.CurrentState}}|{{.Error}}'
    )
  done
fi

exit "$failed"
