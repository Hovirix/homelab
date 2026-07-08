# Roles

Ansible roles define the current host configuration behavior for Proxmox nodes.

## Source Paths

- `infrastructure/ansible/roles/common/`
- `infrastructure/ansible/roles/repositories/`
- `infrastructure/ansible/roles/api/`
- `infrastructure/ansible/roles/ssh/`
- `infrastructure/ansible/roles/kernel/`
- `infrastructure/ansible/roles/networking/`
- `infrastructure/ansible/roles/wake_on_lan/`
- `infrastructure/ansible/roles/updates/`
- `infrastructure/ansible/roles/storage/`
- `infrastructure/ansible/roles/backup/`
- `infrastructure/ansible/roles/firewall/`
- `infrastructure/ansible/roles/certificates/`
- `infrastructure/ansible/roles/monitoring/`
- `infrastructure/ansible/roles/notifications/`
- `infrastructure/ansible/roles/cluster/`

## Implemented Roles

- `common`: hostname, `/etc/hosts`, and timezone.
- `repositories`: Debian and Proxmox repository configuration.
- `api`: Proxmox API role, user, ACL, and token lifecycle.
- `ssh`: key-only root access and SSH drop-in config.
- `storage`: ZFS pool validation and safe storage tuning.
- `notifications`: Proxmox SMTP notification target and matcher.
- `certificates`: Proxmox ACME DNS-01 setup.
- `kernel`: kernel command line and VFIO module configuration.
- `networking`: `/etc/network/interfaces` for Proxmox VLAN networking.
- `wake_on_lan`: installs `ethtool` and enables WOL on the physical interface.
- `updates`: apt refresh, dist upgrade, and reboot if required.

## Empty Roles

- `backup`

## Comment-Only Roles

- `firewall`
- `monitoring`
- `cluster`

## Notes

- The empty and comment-only roles are intentionally not managed yet.
