#!/usr/bin/env bash

set -euo pipefail

main() {
  local sops_file="${1:?missing sops file}"

  shift 1

  TF_VAR_opentofu_state_encryption_passphrase="$(
    sops -d \
      --extract '["opentofu"]["state_encryption_passphrase"]' \
      "$sops_file"
  )" tofu "$@"
}

main "$@"
