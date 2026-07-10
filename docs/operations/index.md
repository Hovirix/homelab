# Operations

Operations documents how HX Lab is run.

## Source Paths

- `Taskfile.yml`
- `operations/taskfiles/`
- `operations/scripts/`
- `docs/operations/runbooks/`

## Current Scope

- Task entrypoints for Ansible, OpenTofu, Talos, Cluster bootstrap, and GitOps.
- Runbooks for repeatable operational procedures.

## Sections

- [Proxmox API Token](./runbooks/proxmox-api-token)
- [Proxmox Bootstrap, VLANs, and OpenWrt](./runbooks/proxmox-bootstrap-vlan-openwrt)
- [Cluster Bootstrap](./runbooks/cluster-bootstrap)
- [DNS and Email](./runbooks/dns-and-email)
- [Flux SOPS Age Decryption](./runbooks/sops-age-flux)
- [Talos on Proxmox with OpenTofu](./runbooks/talos-proxmox-opentofu)
- [TrueNAS SCALE Setup Runbook](./runbooks/truenas)
- [Wake on LAN](./runbooks/wake-on-lan)
