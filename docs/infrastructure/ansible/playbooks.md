# Playbooks

Ansible playbooks are the operational entrypoints for Proxmox host configuration.

## Source Paths

- `operations/taskfiles/ansible.yml`
- `infrastructure/ansible/playbooks/bootstrap.yml`
- `infrastructure/ansible/playbooks/configure.yml`
- `infrastructure/ansible/playbooks/networking.yml`
- `infrastructure/ansible/playbooks/maintenance.yml`

## Current Entry Points

- `bootstrap.yml` bootstraps Proxmox hosts with repositories and SSH.
- `configure.yml` applies the full host configuration, including Wake-on-LAN.
- `networking.yml` migrates hosts to VLAN networking one host at a time.
- `maintenance.yml` runs package maintenance one host at a time.

## Task Wrapper

- `task ansible:bootstrap`
- `task ansible:configure`
- `task ansible:networking`
- `task ansible:maintenance`
- `task ansible:check`
- `task ansible:syntax`
- `task ansible:lint`

## Notes

- `bootstrap` prompts for the initial SSH password with `--ask-pass`; later runs should use SSH keys installed by the bootstrap playbook.
- `networking.yml` and `maintenance.yml` use `serial: 1`.
- `check` runs `configure.yml` in check mode with diff output.
