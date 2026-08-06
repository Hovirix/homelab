#!/usr/bin/env bash

set -euo pipefail

main() {
  local script_dir
  local root_dir
  local platform_sops_file

  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  root_dir="$(cd -- "$script_dir/../.." && pwd)"
  platform_sops_file="${1:-$root_dir/secrets/platform.sops.yaml}"

  if [[ ! -f $platform_sops_file ]]; then
    printf 'Platform secrets file does not exist: %s\n' "$platform_sops_file" >&2
    return 1
  fi

  sops -d "$platform_sops_file" |
    yq -r '
      ..
      | select(tag != "!!map" and tag != "!!seq")
      | {
          "name": (path | join("_")),
          "value": .
        }
      | @json
    ' |
    while IFS= read -r secret; do
      reconcile_secret "$secret"
    done
}

reconcile_secret() {
  local secret="${1:?missing secret json}"
  local name
  local value

  name="$(printf '%s' "$secret" | yq -r '.name' -)"
  value="$(printf '%s' "$secret" | yq -r '.value' -)"

  if docker secret inspect "$name" >/dev/null 2>&1; then
    printf 'Skipping existing secret: %s\n' "$name"
    return 0
  fi

  printf 'Creating secret: %s\n' "$name"
  printf '%s' "$value" | docker secret create "$name" - >/dev/null
}

main "$@"
