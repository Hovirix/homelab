# HX Lab

HX Lab is a desired-state homelab repository. Treat repository code as intent; runtime output is only observed evidence from that command.

## Architecture

- Active stack: Proxmox VE, Fedora CoreOS VMs, Docker Swarm, Traefik, Cloudflared, Authentik, AdGuard Home, PostgreSQL/Valkey, and observability/application stacks. Network infrastructure itself is managed separately.
- `infrastructure/ansible/` configures only Proxmox hosts/datacenter resources. The active inventory is `pve1.home.hovirix.dev` as `root`.
- `infrastructure/opentofu/stacks/` has four direct stacks: `adguardhome`, `proxmox`, `cloudflare`, and `authentik`. There are no current modules; add one only for a durable boundary or real repetition.
- Fedora CoreOS source is `infrastructure/opentofu/stacks/proxmox/fcos/fcos.bu`; `infrastructure/opentofu/stacks/proxmox/build/fcos.ign` is generated and ignored. Regenerate it instead of editing it.
- Live application data is on Proxmox ZFS and mounted into FCOS through VirtioFS. TrueNAS is the Proxmox backup target, not live service storage.
- `platform/` is Docker Swarm desired state. Stack names and deployment order come from `operations/taskfiles/services.yml`; notably, `platform/applications/paperless-ngx` deploys as `paperless`.
- `.opencode/` contains repository-local OpenCode configuration, agents, commands, and skills; do not treat it as platform application code.

## Development And Validation

- Format with `nix fmt`; Treefmt excludes `secrets/**`.
- Full local validation is `task check`, which runs `task check:lint` then `task check:security`.
- `task check` does not run formatting, `tofu validate`, Butane rendering, or Docker stack rendering; add focused validation when changed paths require it.
- Security checks generate ignored SBOM output under `.artifacts/sbom` with Syft, then scan it with Trivy.

## Operations

- Prefer Taskfile entrypoints over raw tools when secrets, stack ordering, or host selection are involved.
- Use `task infra:plan`, `task infra:apply`, or `task infra:destroy` for OpenTofu. They initialize stacks and use `operations/scripts/tofu.sh` for SOPS-backed R2 credentials and state encryption.
- Plan/apply order is `adguardhome`, `proxmox`, `cloudflare`, `authentik`; destroy order is reversed. Plan/apply also regenerate FCOS Ignition, and planning writes ignored initialization/build artifacts.
- Keep each stack's `.terraform.lock.hcl` tracked; never edit state or generated `.terraform/` content.
- Proxmox Ansible preview/apply commands are `task pve:plan` and `task pve:apply`; `site.yml` imports host config, node-local Proxmox config, then datacenter config.
- Swarm/service tasks use `operations/scripts/swarm-host.sh`, which picks the first reachable configured node reporting active Swarm membership; it does not verify manager status independently.
- `task deploy` orders secrets, Traefik, Cloudflared, PostgreSQL, Valkey, Authentik, observability, Vaultwarden, then Paperless. Secret delivery creates missing secrets only; it does not rotate existing ones.
- `task bootstrap` runs infrastructure apply, Proxmox Ansible apply, Swarm init, then service deployment. Treat it as convergence, not guaranteed zero-state bootstrap: provider credentials and the Authentik endpoint may need to exist first.
- `task status` contacts the live Swarm. `task swarm:nuke` has no prompt and removes every stack and Swarm secret visible through the selected endpoint.

## Commit Convention

- Format is Conventional Commits: `type(scope): description`.
- Established types are `fix`, `refactor`, `chore`, and `feat`; established scopes include `infrastructure`, `platform`, `operations`, `deps`, `tools`, and `secrets`.
- Keep the description lowercase. Do not commit, amend, or push unless explicitly requested.

## Secrets And Safety

- Secret material lives in `secrets/*.sops.yaml`; do not decrypt or print it to inspect values. Repo-local OpenCode config denies direct `sops` bash commands.
- Remote mutation, backup/restore execution, and destructive commands require explicit user authorization. Some mutating Task entrypoints do not prompt; infra apply/destroy prompt but pass `-auto-approve` to OpenTofu.
- When invoked, pre-commit runs full-repository `nix fmt` and `trivy --config security/trivy.yaml fs --scanners secret .`, regardless of staged paths.
- Keep traditional documentation minimal. Executable workflows are the operational source of truth; reserve `AGENTS.md` and skills for constraints and procedures code cannot express.
