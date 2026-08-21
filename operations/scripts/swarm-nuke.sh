#!/usr/bin/env bash
set -euo pipefail

stacks=$(docker stack ls --format '{{.Name}}')

if [[ -z $stacks ]]; then
  printf 'No stacks deployed.\n'
  exit 0
fi

printf 'Removing stacks:\n'
while IFS= read -r stack; do
  printf '  • %s\n' "$stack"
  docker stack rm "$stack" >/dev/null 2>&1 || true
done <<<"$stacks"

printf '\nWaiting for drain...\n'

attempt=0
while [[ $(docker stack ls --format '{{.Name}}' | wc -l) -gt 0 ]]; do
  attempt=$((attempt + 1))
  remaining=$(docker stack ls --format '{{.Name}}')
  printf '  pass %d — %d remaining\n' "$attempt" "$(echo "$remaining" | wc -l)"
  while IFS= read -r stack; do
    docker stack rm "$stack" >/dev/null 2>&1 || true
  done <<<"$remaining"
  sleep 5
done

printf 'Done.\n'

secrets=$(docker secret ls --format '{{.Name}}')

if [[ -n $secrets ]]; then
  count=$(echo "$secrets" | wc -l)
  printf '\nRemoving %d secrets:\n' "$count"
  while IFS= read -r secret; do
    printf '  • %s\n' "$secret"
    docker secret rm "$secret" >/dev/null 2>&1 || true
  done <<<"$secrets"
fi

printf 'Done.\n'
