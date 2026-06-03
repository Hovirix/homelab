# Cloudflare Stack

The Cloudflare OpenTofu stack manages Zero Trust Access for `home.hovirix.dev`.

## Source Paths

- `infrastructure/opentofu/stacks/prod/cloudflare/`
- `infrastructure/opentofu/modules/cloudflare/zero_trust_access/`
- `infrastructure/opentofu/modules/cloudflare/zero_trust_access_application/`
- `infrastructure/opentofu/modules/cloudflare/zero_trust_access_identity_provider/`
- `infrastructure/opentofu/modules/cloudflare/zero_trust_access_policy/`
- `infrastructure/opentofu/modules/cloudflare/zero_trust_exposed_application/`
- `infrastructure/opentofu/modules/cloudflare/zero_trust_tunnel_cloudflared/`

## Current State

- The stack manages the `homelab` tunnel.
- Authentik is configured as the identity provider.
- Access policies exist for `admins` and `users`, both restricted to `FR`.
- Exposed applications include Authentik, Immich, Paperless, Vaultwarden, and Grafana.

## Inputs

- Cloudflare account and zone IDs.
- SOPS-backed Cloudflare API token.
- SOPS-backed Authentik OAuth client secrets.
- Application upstream addresses.

## Resources

- [`provider "sops"`](https://registry.terraform.io/providers/carlpett/sops/latest)
- [`provider "cloudflare"`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest)
- [`module "zero_trust_access"`](https://github.com/Hovirix/homelab/blob/main/infrastructure/opentofu/stacks/prod/cloudflare/main.tf)
