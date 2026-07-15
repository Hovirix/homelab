#!/usr/bin/env bash

set -euo pipefail

main() {
  local infrastructure_sops_file="${1:?missing infrastructure sops file}"

  shift 1

  AWS_ACCESS_KEY_ID="$(
    sops -d \
      --extract '["opentofu"]["state"]["backend"]["access_key_id"]' \
      "$infrastructure_sops_file"
  )" \
  AWS_SECRET_ACCESS_KEY="$(
    sops -d \
      --extract '["opentofu"]["state"]["backend"]["secret_access_key"]' \
      "$infrastructure_sops_file"
  )" \
  TF_VAR_opentofu_state_encryption_passphrase="$(
    sops -d \
      --extract '["opentofu"]["state"]["encryption_passphrase"]' \
      "$infrastructure_sops_file"
  )" tofu "$@"
}

main "$@"
