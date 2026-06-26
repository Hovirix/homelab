# Wake on LAN

Use these commands to wake lab hosts from a machine on the same network.

## Known Manual Targets

- TrueNAS: `etherwake -i br-lan.30 24:97:ed:31:3d:a0`
- pve1: `etherwake -i br-lan.20 58:47:ca:73:90:76`

## Ansible-Managed Proxmox WOL

- `task ansible:configure` also applies the `wake_on_lan` role.
- The role installs `ethtool`, enables `wake-on-lan.service`, and turns WOL on for `{{ proxmox_network_interface }}`.
- Current host vars point the Proxmox nodes at `nic0`.

## Missing Data

- `pve2` and `pve3` MAC addresses are not documented in the repository yet.
- Add their WOL commands here once the addresses are known.
