# Inventory

Ansible inventory for Proxmox host configuration.

## Source Paths

- `infrastructure/ansible/inventories/hosts.yml`
- `infrastructure/ansible/inventories/group_vars/proxmox.yml`
- `infrastructure/ansible/inventories/host_vars/pve1.yml`
- `infrastructure/ansible/inventories/host_vars/pve2.yml`
- `infrastructure/ansible/inventories/host_vars/pve3.yml`

## Current State

- The active Proxmox host is `pve1` at `10.20.0.11`.
- `pve2` and `pve3` are present as commented planned hosts.
- The managed Proxmox domain is `home.hovirix.dev`.
- Management VLAN is `20`.
- Allowed VLANs are `20` management, `40` Kubernetes, and `60` air-gapped/security lab.

## Role Variables

- Hostnames, timezone, SSH access, VLAN settings, kernel tuning, backup retention, and API token settings are declared in `group_vars/proxmox.yml`.
