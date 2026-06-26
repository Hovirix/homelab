# Talos on Proxmox with OpenTofu

Start here when provisioning or changing the current Talos VM stack on Proxmox.

## Source Paths

- `docs/infrastructure/opentofu/index.md`
- `docs/infrastructure/opentofu/stacks/proxmox.md`
- `infrastructure/opentofu/stacks/prod/proxmox/main.tf`
- `operations/taskfiles/opentofu.yml`
- `operations/scripts/tofu`

## Current State

- The stack currently manages one enabled VM: `prod-k8s-01` on `pve1` with VM ID `101`.
- Talos is pinned to `v1.13.3`.
- The VM uses VLAN `40`.
- `prod-k8s-02` and `prod-k8s-03` stay commented until `pve2` and `pve3` exist.

## Provisioning Flow

1. Confirm `secrets/infrastructure.sops.yaml` is present and decryptable.
2. Run `task tofu:init stack=proxmox`.
3. Run `task tofu:validate stack=proxmox`.
4. Run `task tofu:plan stack=proxmox`.
5. Review the plan carefully.
6. Run `task tofu:apply stack=proxmox`.

## Validation

- Confirm the VM exists in Proxmox with the expected VM ID.
- Confirm the Talos image version still matches `v1.13.3`.
- Confirm the VM is attached to VLAN `40`.

## Notes

- The OpenTofu wrapper injects the state encryption passphrase from SOPS at runtime.
- Keep the stack changes small so VM lifecycle changes stay easy to review.
