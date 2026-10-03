# HX Lab

HX Lab is a desired-state homelab repository. Repository configuration describes intended state; runtime state requires runtime evidence.

## Map

- `infrastructure/opentofu/` manages infrastructure.
- `infrastructure/ansible/` configures Proxmox VE.
- `platform/` contains Docker Swarm desired state.
- `operations/` contains Task workflows and supporting scripts.
- `secrets/` contains encrypted production secrets.
- `operations/taskfiles/services.yml` owns service deployment order and stack naming.

Fedora CoreOS is authored in `infrastructure/opentofu/stacks/proxmox/fcos/fcos.bu`; generated `build/fcos.ign` must not be edited directly.

Persistent application data is independent from disposable Swarm state.

Observability is intentionally `Alloy -> VictoriaMetrics/Loki -> Grafana -> mcp-grafana -> OpenCode`. Do not redesign it unless explicitly requested.

## Boundaries

Prefer Task entrypoints when they encapsulate credentials, ordering, host selection, secrets, or generated artifacts.

Remote mutation, deployment, restore, destructive storage operations, secret rotation, and infrastructure apply/destroy require explicit user authorization.

Never decrypt or print secret values for inspection.

Do not infer runtime health, placement, or successful deployment from repository configuration.

Use `task check:lint` for normal local validation. Run `task check` or `task check:security` only when explicitly requested.

## Git

Use Conventional Commits: `type(scope): lowercase description`.

Do not commit, amend, push, rewrite history, or bypass hooks unless explicitly requested.

## Documentation

Keep documentation minimal. Executable configuration is the operational source of truth.
