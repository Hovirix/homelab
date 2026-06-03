# OpenTofu

## Source Paths

- `infrastructure/opentofu/stacks/`
- `infrastructure/opentofu/modules/`
- `operations/taskfiles/opentofu.yml`
- `operations/scripts/tofu`

## Overview

OpenTofu provisions and maintains the production infrastructure stacks under `infrastructure/opentofu/stacks/`.

## Current Production Stacks

### Proxmox

- Provisions a Talos-based Kubernetes cluster on Proxmox.
- Currently enabled node: `prod-k8s-01` on `pve1` with VM ID `101`.
- Planned nodes `prod-k8s-02` and `prod-k8s-03` are commented until `pve2` and `pve3` exist.

- [Stack doc](./stacks/proxmox)

### Cloudflare

- Manages Zero Trust Access for `home.hovirix.dev`.
- Uses the `homelab` tunnel.
- Connects to Authentik as the identity provider.
- Manages access policies and exposed applications for Authentik, Immich, Paperless, Vaultwarden, and Grafana.

- [Stack doc](./stacks/cloudflare)

### Authentik

- Manages OAuth2 applications for Cloudflare, Grafana, Immich, and Paperless.
- Consumes identity secrets from SOPS.

- [Stack doc](./stacks/authentik)

### AdGuard Home

- Manages DNS rewrites for the Proxmox hosts.
- Maps `pve1`, `pve2`, and `pve3` hostnames to the management network addresses.

- [Stack doc](./stacks/adguardhome)

## State Encryption

- [State Encryption](./state-encryption)
