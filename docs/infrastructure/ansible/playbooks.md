# Playbooks

Ansible playbooks are the operational entrypoints for Proxmox host configuration.

## Source Paths

- `operations/taskfiles/ansible.yml`
- `infrastructure/ansible/playbooks/bootstrap.yml`
- `infrastructure/ansible/playbooks/configure.yml`
- `infrastructure/ansible/playbooks/storage.yml`
- `infrastructure/ansible/playbooks/notifications.yml`
- `infrastructure/ansible/playbooks/networking.yml`
- `infrastructure/ansible/playbooks/maintenance.yml`

## Current Entry Points

- `bootstrap.yml` bootstraps Proxmox hosts with repositories and SSH.
- `configure.yml` applies the full host configuration, including storage tuning and Wake-on-LAN.
- `storage.yml` applies only the ZFS storage role.
- `notifications.yml` applies only the Proxmox SMTP notification role.
- `networking.yml` migrates hosts to VLAN networking one host at a time.
- `maintenance.yml` runs package maintenance one host at a time.

## Task Wrapper

- `task ansible:bootstrap`
- `task ansible:configure`
- `task ansible:storage`
- `task ansible:notifications`
- `task ansible:networking`
- `task ansible:maintenance`
- `task ansible:check`
- `task ansible:syntax`
- `task ansible:lint`

## Notes

- `bootstrap` prompts for the initial SSH password with `--ask-pass`; later runs should use SSH keys installed by the bootstrap playbook.
- `storage` is a targeted entrypoint for ZFS validation and safe storage tuning.
- `notifications` is a targeted entrypoint for Proxmox SMTP notification configuration.
- `networking.yml` and `maintenance.yml` use `serial: 1`.
- `check` runs `configure.yml` in check mode with diff output.
