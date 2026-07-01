# Secrets

HX Lab keeps infrastructure secrets in SOPS-encrypted files instead of plain text.

## Source Paths

- `secrets/infrastructure.sops.yaml`
- `operations/scripts/tofu`
- `infrastructure/opentofu/stacks/prod/proxmox/providers.tf`
- `infrastructure/ansible/roles/api/tasks/main.yml`
- `infrastructure/ansible/roles/notifications/tasks/main.yml`

## Current State

- OpenTofu reads the Proxmox API token from SOPS.
- The Proxmox API token is created by Ansible and stored as a UUID value in SOPS.
- Proxmox SMTP notification credentials are read from `secrets/infrastructure.sops.yaml`.
- OpenTofu state encryption is configured per stack.

## Notes

- Do not document decrypted secret values.
- Document secret names, storage locations, and consuming code only.
