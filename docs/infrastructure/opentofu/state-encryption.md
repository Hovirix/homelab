# State Encryption

OpenTofu state and plan encryption are enforced in the production stacks.

## Source Paths

- `infrastructure/opentofu/stacks/prod/proxmox/backend.tf`
- `infrastructure/opentofu/stacks/prod/cloudflare/backend.tf`
- `operations/scripts/tofu`
- `operations/taskfiles/opentofu.yml`

## Current Behavior

- Each stack declares a `opentofu_state_encryption_passphrase` variable.
- Encryption uses a PBKDF2 key provider and AES-GCM method.
- State encryption is enforced for both state and plan.
- The wrapper script reads the passphrase from `secrets/infrastructure.sops.yaml`.

## Notes

- This page documents the encryption wiring only.
- It does not describe decrypted state contents or secret material.
