# Infrastructure

Infrastructure documentation maps directly to the code under `infrastructure/`.

## Source Paths

- `infrastructure/ansible/`
- `infrastructure/opentofu/`
- `secrets/infrastructure.sops.yaml`

## Current Scope

- Proxmox host configuration with Ansible.
- OpenTofu stacks for Proxmox, Cloudflare, Authentik, and AdGuard Home.
- SOPS-backed secret values used by infrastructure tooling.

## Sections

- [Ansible](./ansible/)
- [OpenTofu](./opentofu/)
- [Secrets](./secrets)
