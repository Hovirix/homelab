# HX Lab

HX Lab is a desired-state homelab repository. Treat repository code as intent; runtime output is only observed evidence from that command.

## Architecture

- Active stack: Proxmox VE, Fedora CoreOS VMs, Docker Swarm, Traefik, Cloudflared, Authentik, AdGuard Home, PostgreSQL/Valkey, and observability/application stacks. Network infrastructure itself is managed separately.
- `infrastructure/ansible/` configures only Proxmox hosts/datacenter resources. The active inventory is `pve.home.hovirix.dev` as `root`.
- `infrastructure/opentofu/stacks/` has four direct stacks: `adguardhome`, `proxmox`, `cloudflare`, and `authentik`. There are no current modules; add one only for a durable boundary or real repetition.
- Fedora CoreOS source is `infrastructure/opentofu/stacks/proxmox/fcos/fcos.bu`; `infrastructure/opentofu/stacks/proxmox/build/fcos.ign` is generated and ignored. Regenerate it instead of editing it.
- Live application data is on Proxmox ZFS and mounted into FCOS through VirtioFS.
- `platform/` is Docker Swarm desired state. Stack names and deployment order come from `operations/taskfiles/services.yml`; notably, `platform/applications/paperless-ngx` deploys as `paperless`.
- `.opencode/` contains repository-local OpenCode configuration, agents, commands, and skills; do not treat it as platform application code.

## Development And Validation

- Format with `treefmt`; Treefmt excludes `secrets/**`.
- Full local validation is `task check`, which runs linting and security checks, including `tofu validate`, strict Butane rendering, Docker stack rendering, Treefmt verification, Syft SBOM generation, Grype vulnerability scans, and Trivy secret/IaC scans.
- Local validation proves configuration, not deployment or runtime health.
- Do not run `task check:security` autonomously; run it only when the user explicitly requests it.

## Operations

- Prefer Taskfile entrypoints over raw tools when secrets, stack ordering, or host selection are involved.
- Use `task infra:plan`, `task infra:apply`, or `task infra:destroy` for OpenTofu. They initialize stacks and use `operations/scripts/tofu.sh` for SOPS-backed R2 credentials and state encryption.
- Plan/apply order is `adguardhome`, `proxmox`, `cloudflare`, `authentik`; destroy order is reversed. Plan/apply also regenerate FCOS Ignition, and planning writes ignored initialization/build artifacts.
- Keep each stack's `.terraform.lock.hcl` tracked; never edit state or generated `.terraform/` content.
- Proxmox Ansible preview/apply commands are `task pve:plan` and `task pve:apply`; `site.yml` imports host config, node-local Proxmox config, then datacenter config.
- Swarm/service tasks use `operations/scripts/swarm-host.sh`, which selects the first reachable active Swarm manager.
- `task deploy` orders secrets, Traefik, Cloudflared, PostgreSQL, Valkey, Authentik, observability, Vaultwarden, then Paperless. Secret delivery creates missing secrets only; it does not rotate existing ones.

## Observability

Observability architecture is frozen: Alloy -> VictoriaMetrics/Loki -> Grafana -> mcp-grafana -> OpenCode. Do not redesign or replace components unless explicitly requested.

- `task bootstrap` runs infrastructure apply, Proxmox Ansible apply, Swarm init, then service deployment. Treat it as convergence, not guaranteed zero-state bootstrap: provider credentials and the Authentik endpoint may need to exist first.
- `task status` contacts the live Swarm. `task swarm:nuke` has no prompt and removes every stack and Swarm secret visible through the selected endpoint.

## Commit Convention

- Format is Conventional Commits: `type(scope): description`.
- Established types are `fix`, `refactor`, `chore`, and `feat`; established scopes include `infrastructure`, `platform`, `operations`, `deps`, `tools`, and `secrets`.
- Keep the description lowercase. Do not commit, amend, or push unless explicitly requested.

## Secrets And Safety

- Secret material lives in `secrets/*.sops.yaml`; do not decrypt or print it to inspect values. Repo-local OpenCode config denies direct `sops` and secret-delivery wrappers, but other approved workflows can still require secrets.
- Remote mutation, backup/restore execution, and destructive commands require explicit user authorization. Some mutating Task entrypoints do not prompt; infra apply/destroy prompt but pass `-auto-approve` to OpenTofu.
- When invoked, pre-commit runs full-repository `treefmt` and `trivy --config security/trivy.yaml fs --scanners secret .`, regardless of staged paths.
- Keep traditional documentation minimal. Executable workflows are the operational source of truth; reserve `AGENTS.md` and skills for constraints and procedures code cannot express.
