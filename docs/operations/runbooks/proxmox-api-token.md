# Proxmox API Token

OpenTofu reads the Proxmox API token from `secrets/infrastructure.sops.yaml`.

```yaml
proxmox:
  api_token: PVEAPIToken=opentofu@pve!opentofu=<secret>
```

Ansible creates the Proxmox API user and token. Proxmox only returns the token secret when the token is created, so Ansible prints newly generated token output for manual storage in SOPS.

## Initial Setup

Run the API role:

```bash
ansible-playbook infrastructure/ansible/playbooks/configure.yml --tags api
```

If the token did not exist, Ansible prints the generated token output. Store the full token value in `secrets/infrastructure.sops.yaml` as `proxmox.api_token`.

The value must keep the full Proxmox token format:

```text
PVEAPIToken=opentofu@pve!opentofu=<secret>
```

## Rotation

Set `token_regenerate: true` for the API user in `infrastructure/ansible/inventories/group_vars/proxmox.yml`, then run:

```bash
ansible-playbook infrastructure/ansible/playbooks/configure.yml --tags api
```

Ansible deletes the existing token, creates a replacement, and prints the new token output.

Store the new full token value in SOPS, then set `token_regenerate` back to `false`.

Run OpenTofu after SOPS contains the current token:

```bash
tofu plan
```
