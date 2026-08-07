#!/usr/bin/env bash

set -euo pipefail

main() {
  local script_dir
  local root_dir
  local platform_sops_file
  local identity_sops_file

  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  root_dir="$(cd -- "$script_dir/../.." && pwd)"
  platform_sops_file="${1:-$root_dir/secrets/platform.sops.yaml}"
  identity_sops_file="${2:-$root_dir/secrets/identity.sops.yaml}"

  if [[ ! -f $platform_sops_file ]]; then
    printf 'Platform secrets file does not exist: %s\n' "$platform_sops_file" >&2
    return 1
  fi

  if [[ ! -f $identity_sops_file ]]; then
    printf 'Identity secrets file does not exist: %s\n' "$identity_sops_file" >&2
    return 1
  fi

  reconcile_file "$platform_sops_file" 'true'
  reconcile_file "$identity_sops_file" 'path[0] == "oauth"'
}

reconcile_file() {
  local sops_file="${1:?missing sops file}"
  local filter="${2:?missing yq filter}"

  sops -d "$sops_file" |
    yq -r '
      ..
      | select(tag != "!!map" and tag != "!!seq")
      | select('"$filter"')
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
