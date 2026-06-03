# Roles

Ansible roles define the current host configuration behavior for Proxmox nodes.

## Source Paths

- `infrastructure/ansible/roles/common/`
- `infrastructure/ansible/roles/repositories/`
- `infrastructure/ansible/roles/api/`
- `infrastructure/ansible/roles/ssh/`
- `infrastructure/ansible/roles/kernel/`
- `infrastructure/ansible/roles/networking/`
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
- `kernel`: kernel command line and VFIO module configuration.
- `networking`: `/etc/network/interfaces` for Proxmox VLAN networking.
- `updates`: apt refresh, dist upgrade, and reboot if required.

## Empty Roles

- `storage`
- `backup`

## Comment-Only Roles

- `firewall`
- `certificates`
- `monitoring`
- `notifications`
- `cluster`

## Notes

- The empty and comment-only roles are intentionally not managed yet.
- The docs should treat those as planned work, not active state.
