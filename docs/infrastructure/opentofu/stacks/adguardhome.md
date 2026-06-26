# AdGuard Home Stack

The AdGuard Home OpenTofu stack manages DNS rewrites for the Proxmox and TrueNAS hostnames.

## Source Paths

- `infrastructure/opentofu/stacks/prod/adguardhome/`

## Current State

- The stack defines DNS rewrites for `pve1.home.hovirix.dev`, `pve2.home.hovirix.dev`, `pve3.home.hovirix.dev`, and `truenas.home.hovirix.dev`.
- Each hostname maps to the management network address declared in the stack.
- The stack uses SOPS-backed credentials for the AdGuard Home provider.

## Inputs

- AdGuard Home host address and credentials.
- SOPS-backed `adguardhome.username` and `adguardhome.password` values.

## Resources

- [`provider "sops"`](https://registry.terraform.io/providers/carlpett/sops/latest)
- [`provider "adguard"`](https://registry.terraform.io/providers/gmichels/adguard/latest)
- [`resource "adguard_rewrite" "records"`](https://github.com/Hovirix/homelab/blob/main/infrastructure/opentofu/stacks/prod/adguardhome/main.tf)
