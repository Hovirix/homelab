# Proxmox API Token

OpenTofu reads the Proxmox API token from `secrets/infrastructure.sops.yaml`. The provider constructs the full token string by concatenating the token ID with the secret value from SOPS.

```yaml
proxmox:
  api_token: <uuid>
```

Provider configuration in `infrastructure/opentofu/stacks/prod/proxmox/providers.tf`:

```hcl
api_token = "opentofu@pve!opentofu=${data.sops_file.infrastructure.data["proxmox.api_token"]}"
```

Ansible creates the Proxmox API user and token. Proxmox only returns the token secret when the token is created, so Ansible prints the generated token value (UUID only) for manual storage in SOPS.

## Initial Setup

Run the API role:

```bash
ansible-playbook infrastructure/ansible/playbooks/configure.yml --tags api
```

If the token did not exist, Ansible prints the generated UUID. Store only the UUID value in `secrets/infrastructure.sops.yaml` as `proxmox.api_token`.

```yaml
proxmox:
  api_token: <uuid>
```

## Rotation

Set `token_regenerate: true` for the API user in `infrastructure/ansible/inventories/group_vars/proxmox.yml`, then run:

```bash
ansible-playbook infrastructure/ansible/playbooks/configure.yml --tags api
```

Ansible deletes the existing token, creates a replacement, and prints the new UUID.

Store the new UUID in SOPS, then set `token_regenerate` back to `false`.

Run OpenTofu after SOPS contains the current token:

```bash
tofu plan
```
