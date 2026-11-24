# Context

HX Lab is a desired-state homelab repository treated as production.

## Map

- `infrastructure/` manages infrastructure.
- `infrastructure/incusos/` contains IncusOS installation seeds.
- `platform/backup/` configures the backup container with Ansible.
- `platform/` contains Docker Swarm desired state.
- `operations/` contains Task workflows and worker scripts.
- `secrets/` contains encrypted production secrets.

- Infra = IncusOS, Fedora CoreOS, Cloudflare, Hetzner (backups)
- Platform = Docker Swarm
- Operations = Taskfile

Storage is shared between swarm nodes (Virtiofs under ZFS).
Networking is managed separately at `https://github.com/hovirix/netlab`.

## Philosophy

- GitOps
- KISS
- DRY
- Minimal dependencies
- No unnecessary documentation

## Code constraints

- Strictly minimal code
- Repetition and clarity > abstraction
- Upstream implementations > custom glue code
- Taskfiles call the script directly no need for bash python prefix before or path fidings in worker scripts.
- Task should orchestrate workers; workers should not call each other.

## Git

Prefix every git commands with rtk.

Use `type(scope): lowercase description` for commits, issues, and pull requests.

Allowed types: `feat`, `fix`, `refactor`, `chore`.

Allowed scopes: `infrastructure`, `platform`, `operations`, `security`, `secrets`, `tools`, `deps`.

Issues: use `Goal`, `Context`, and `Done when` headings.

Pull requests: use `What` and `Checks` headings in the body.
