#!/usr/bin/env bash

set -euo pipefail

main() {
  local cmd="${1:?missing tofu command}"
  local sops_file="${2:?missing sops file}"

  shift 2

  TF_VAR_opentofu_state_encryption_passphrase="$(
    sops -d \
      --extract '["opentofu"]["state_encryption_passphrase"]' \
      "$sops_file"
  )" tofu "$cmd" "$@"
}

main "$@"
