# Proxmox Stack

The Proxmox OpenTofu stack provisions the Talos-based Kubernetes cluster on Proxmox.

## Source Paths

- `infrastructure/opentofu/stacks/prod/proxmox/`
- `infrastructure/opentofu/modules/proxmox/talos_cluster/`
- `infrastructure/opentofu/modules/proxmox/talos_vm/`

## Current State

- The stack currently manages one enabled VM: `prod-k8s-cp-01` on `pve1` with VM ID `101`.
- Planned nodes `prod-k8s-cp-02` and `prod-k8s-cp-03` are present but commented until `pve2` and `pve3` are available.
- The stack pins Talos `v1.13.3` and the Talos image schematic ID used by the cluster module.

## Inputs

- Proxmox endpoint configuration.
- SOPS-backed Proxmox API token.
- Cluster sizing and VM placement.
- VLAN 40 network attachment.

## Resources

- [`provider "sops"`](https://registry.terraform.io/providers/carlpett/sops/latest)
- [`provider "proxmox"`](https://registry.terraform.io/providers/bpg/proxmox/latest)
- [`module "kubernetes_cluster"`](https://github.com/Hovirix/homelab/blob/main/infrastructure/opentofu/stacks/prod/proxmox/main.tf)
