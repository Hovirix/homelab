# Authentik Stack

The Authentik OpenTofu stack manages OAuth2 applications and redirect wiring for services that depend on Authentik.

## Source Paths

- `infrastructure/opentofu/stacks/prod/authentik/`
- `infrastructure/opentofu/modules/authentik/oauth2_application/`

## Current State

- Managed OAuth2 applications exist for Cloudflare, Grafana, Immich, and Paperless.
- The Cloudflare application uses the Cloudflare Access callback URL.
- Grafana, Immich, and Paperless each have service-specific redirect URIs.

## Inputs

- SOPS-backed OAuth client IDs and client secrets.
- Authentik provider URL and token.
- Application redirect URIs.

## Resources

- [`provider "sops"`](https://registry.terraform.io/providers/carlpett/sops/latest)
- [`provider "authentik"`](https://registry.terraform.io/providers/goauthentik/authentik/latest)
- [`module "cloudflare"`](https://github.com/Hovirix/homelab/blob/main/infrastructure/opentofu/stacks/prod/authentik/main.tf)
- [`module "grafana"`](https://github.com/Hovirix/homelab/blob/main/infrastructure/opentofu/stacks/prod/authentik/main.tf)
- [`module "immich"`](https://github.com/Hovirix/homelab/blob/main/infrastructure/opentofu/stacks/prod/authentik/main.tf)
- [`module "paperless"`](https://github.com/Hovirix/homelab/blob/main/infrastructure/opentofu/stacks/prod/authentik/main.tf)
