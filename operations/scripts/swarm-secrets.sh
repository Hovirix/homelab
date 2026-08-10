#!/usr/bin/env bash

set -uo pipefail

files=(
  "./secrets/platform.sops.yaml"
  "./secrets/identity.sops.yaml"
)

for file in "${files[@]}"; do
  sops -d "$file" |
    yq -r '
      ..
      | select(tag != "!!map" and tag != "!!seq")
      | [(path | join("_")), .]
      | @tsv
    ' |
    while IFS=$'\t' read -r name value; do
      printf 'Creating secret: %s\n' "$name"
      printf '%s' "$value" | docker secret create "$name" - || true
    done
done
