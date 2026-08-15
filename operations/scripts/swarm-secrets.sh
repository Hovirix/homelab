#!/usr/bin/env bash

set -euo pipefail

files=(
  "./secrets/platform.sops.yaml"
  "./secrets/identity.sops.yaml"
)

for file in "${files[@]}"; do
  sops -d "$file" |
    yq -r '
      ..
      | select(tag != "!!map" and tag != "!!seq")
      | [
          (path | .[1:] | join("_")),
          .
        ]
      | @tsv
    ' |
    while IFS=$'\t' read -r name value; do
      if docker secret inspect "$name" >/dev/null 2>&1; then
        printf 'Secret already exists: %s\n' "$name"
        continue
      fi

      printf 'Creating secret: %s\n' "$name"
      printf '%s' "$value" | docker secret create "$name" -
    done
done
