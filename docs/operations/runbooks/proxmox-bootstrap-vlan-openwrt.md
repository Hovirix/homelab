# Proxmox Bootstrap, VLANs, and OpenWrt

Start here when a Proxmox host must move from temporary untagged access to the VLAN trunk used by the managed configuration.

## Source Paths

- `docs/infrastructure/ansible/inventory.md`
- `docs/infrastructure/ansible/playbooks.md`
- `infrastructure/ansible/inventories/group_vars/proxmox.yml`
- `infrastructure/ansible/inventories/host_vars/pve1.yml`
- `infrastructure/ansible/inventories/host_vars/pve2.yml`
- `infrastructure/ansible/inventories/host_vars/pve3.yml`
- `infrastructure/ansible/playbooks/bootstrap.yml`
- `infrastructure/ansible/playbooks/networking.yml`
- `infrastructure/ansible/roles/networking/templates/interfaces.j2`
- `infrastructure/ansible/roles/firewall/tasks/main.yml`

## Current State

- Management VLAN is `20`.
- Allowed VLANs are `20`, `40`, and `60`.
- The managed bridge is VLAN-aware `vmbr0` with `vmbr0.20` as the management interface.
- The host NIC variable is `nic0` on all documented hosts.
- `pve1` is active at `10.20.0.11/24`; `pve2` and `pve3` are planned.

## Switch Port Stance

- Before bootstrap or the first networking migration, set the OpenWrt or switch port connected to the host to untagged/access on VLAN `20`.
- After `networking.yml` completes and the host is reachable again, switch the port back to trunk/tagged mode for VLANs `20`, `40`, and `60`.
- Do not leave the port as access-only once the bridge is VLAN-aware, or tagged traffic for the other VLANs will not pass.

## Bootstrap Sequence

1. Confirm the host is reachable on the current management address.
2. Set the connected switch port to untagged VLAN `20`.
3. Run `task ansible:bootstrap -- --limit pve1`.
4. Confirm SSH key access works after bootstrap.
5. Run `task ansible:networking -- --limit pve1`.
6. Wait for the host to reload networking.
7. Verify `/etc/network/interfaces` now contains VLAN-aware `vmbr0` and `vmbr0.20`.
8. Return the switch port to trunk/tagged VLANs `20`, `40`, and `60`.
9. Verify management access on `10.20.0.11` or the matching host IP.

## Validation

```bash
ping 10.20.0.11
```

```bash
ip addr
```

```bash
bridge vlan show
```

```bash
cat /etc/network/interfaces
```

## Rollback

- If the host drops off the network after trunking, restore the switch port to untagged VLAN `20`.
- Re-run `task ansible:networking -- --limit <host>` after access is restored.
