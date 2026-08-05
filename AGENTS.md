# HX Lab

HX Lab is a personal homelab managed as code. Repository code is desired state; runtime command output is observed state and is evidence only for the command that produced it.

## Active Architecture

```text
Internet
  |
Cloudflare
  |
Cloudflared and ingress
  |
Docker Swarm services
  |
Docker Engine
  |
Fedora CoreOS virtual machines
  |
Proxmox VE
  |
Physical compute and storage
```

```text
Clients
  |
OpenWrt
  |
VLAN routing, DHCP, AdGuard Home DNS and WireGuard
  |
Proxmox and internal services
```

The physical environment includes one Minisforum UM790 Pro systems running Proxmox VE, a separately managed GL.iNet Flint 2 running OpenWrt, and a separate TrueNAS system used primarily as the backup destination. Internal services use `*.home.hovirix.dev`.

The active software direction is Proxmox VE, Fedora CoreOS, Docker Engine, Docker Swarm, OpenTofu, Ansible for Proxmox hosts only, Butane and Ignition for Fedora CoreOS provisioning, Taskfile, SOPS, Cloudflare, Cloudflared, and TrueNAS backups.

## Repository Domains

Infrastructure is rooted at `infrastructure/`. It contains Proxmox Ansible configuration under `infrastructure/ansible/`, OpenTofu modules under `infrastructure/opentofu/modules/`, and OpenTofu stacks under `infrastructure/opentofu/stacks/`.

Current Ansible paths are `infrastructure/ansible/ansible.cfg`, `infrastructure/ansible/inventory.yml`, `infrastructure/ansible/requirements.yml`, `infrastructure/ansible/playbooks/datacenter.yml`, `infrastructure/ansible/playbooks/hosts.yml`, `infrastructure/ansible/playbooks/pve.yml`, `infrastructure/ansible/playbooks/site.yml`, `infrastructure/ansible/roles/datacenter/`, `infrastructure/ansible/roles/host/`, and `infrastructure/ansible/roles/pve/`.

Current OpenTofu module paths are `infrastructure/opentofu/modules/authentik/oauth2_application/`, `infrastructure/opentofu/modules/cloudflare/zero_trust_access/`, `infrastructure/opentofu/modules/cloudflare/zero_trust_access_application/`, `infrastructure/opentofu/modules/cloudflare/zero_trust_access_identity_provider/`, `infrastructure/opentofu/modules/cloudflare/zero_trust_access_policy/`, `infrastructure/opentofu/modules/cloudflare/zero_trust_exposed_application/`, and `infrastructure/opentofu/modules/cloudflare/zero_trust_tunnel_cloudflared/`.

Current OpenTofu stack paths are `infrastructure/opentofu/stacks/adguardhome/`, `infrastructure/opentofu/stacks/authentik/`, `infrastructure/opentofu/stacks/cloudflare/`, and `infrastructure/opentofu/stacks/proxmox/`. Fedora CoreOS Butane source is `infrastructure/opentofu/stacks/proxmox/fcos/fcos.bu`; node input data is `infrastructure/opentofu/stacks/proxmox/fcos/nodes.yaml`; Ignition output under `infrastructure/opentofu/stacks/proxmox/build/` is generated provisioning data.

`platform/` is the intended domain for Docker Swarm runtime definitions, but no tracked platform desired-state files are implemented yet.

Operations is rooted at `Taskfile.yml` and `operations/`. Current operation paths are `operations/taskfiles/configure.yml`, `operations/taskfiles/lint.yml`, `operations/taskfiles/provision.yml`, `operations/taskfiles/security.yml`, `operations/taskfiles/swarm.yml`, `operations/scripts/swarm-init.sh`, `operations/scripts/tofu.sh`, `.github/workflows/checks.yml`, `.github/workflows/security.yml`, and `.pre-commit-config.yaml`.

Security tooling is rooted at `security/` with `security/syft.yaml` and `security/trivy.yaml`. Encrypted secret material is rooted at `secrets/` with `secrets/identity.sops.yaml` and `secrets/infrastructure.sops.yaml`; repository SOPS policy is `.sops.yaml`.

OpenCode project context is rooted at `.opencode/opencode.jsonc` and `.opencode/`. Agents live in `.opencode/agents/`, reusable skills live in `.opencode/skills/`, and user commands live in `.opencode/commands/`.

## Domain Relationships

Infrastructure creates the substrate required before platform services can run. Platform consumes infrastructure and defines desired Docker Swarm runtime state. Operations provides controlled local and CI entrypoints around desired state. Security reviews exposure, privilege, identity, secrets, state confidentiality, and destructive-operation risk across all domains. Secrets are inputs to infrastructure, platform, or operational workflows; they are not an implementation domain by themselves.

There is no documentation domain in this repository. Do not introduce `docs/`, runbooks, ADRs, architecture reports, operational guides, generated documentation, a Documentation Agent, or documentation-specific commands.
