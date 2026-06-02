## Repository

HX Lab is a personal self-hosted DevSecOps platform.

The repository is the source of truth for infrastructure, platform configuration, operational tooling, and documentation.

The codebase should stay simple, boring, readable, and recoverable.

## Principles

- Git is the source of truth.
- Infrastructure is declared as code.
- Configuration is declared as code.
- Secrets are encrypted.
- Changes are small and reviewable.
- Prefer explicit state over implicit behavior.
- Prefer readable code over clever code.
- Prefer local reproducibility.
- Prefer safe defaults.
- Prefer documentation close to the thing it explains.

## Domains

### Infrastructure

Infrastructure is the state required before the platform can run.

**Typical scope:**

- Proxmox
- Cloudflare
- DNS and edge infrastructure
- Talos node provisioning
- Host networking
- Compute
- Storage
- Virtual machines
- OpenTofu
- Ansible

**Typical paths:**

```plaintext
infrastructure/
docs/infrastructure/
docs/architecture/
```

### Platform

Platform is Kubernetes and the cluster services running on top of infrastructure.

**Typical scope:**

- Kubernetes manifests
- Flux resources
- Helm charts
- Ingress controllers
- cert-manager
- external-secrets
- Observability
- Platform identity integrations
- Cluster services

**Typical paths:**

```plaintext
platform/
docs/platform/
```

### Operations

Operations is the way the lab is run, checked, maintained, backed up, restored, and troubleshot.

**Typical scope:**

- Taskfile entrypoints
- Scripts
- Tools
- Checks
- Runbooks
- Maintenance workflows
- Backup workflows
- Restore workflows
- Troubleshooting procedures

**Typical paths:**

```plaintext
Taskfile.yml
operations/
docs/operations/
```

## Boundary Model

```plaintext
Infrastructure defines infrastructure state.
Platform defines Kubernetes and platform state.
Operations defines operational workflows.
```

- Infrastructure state should live in infrastructure paths.
- Platform state should live in platform paths.
- Operational workflows should live in operations paths.

## Code Style

Code should be boring.

**Boring means:**

- Easy to read
- Easy to diff
- Easy to run
- Easy to validate
- Easy to remove
- Easy to recover from

**Prefer:**

- Small files
- Clear names
- Explicit inputs
- Explicit outputs
- Minimal abstraction
- Comments for non-obvious decisions

**Avoid:**

- Clever abstractions
- Hidden side effects
- Large inline scripts
- Broad generic helpers without a real need
- Duplicated configuration
- Undocumented operational behavior

## Naming

- Use lowercase names where practical.
- Use hyphens for human-facing names and documentation paths:

  ```plaintext
  node-replacement.md
  zero-trust.md
  backup-restore.md
  ```

- Use underscores where the tool ecosystem expects them:

  ```plaintext
  group_vars
  host_vars
  ansible variables
  terraform variables
  ```

- Use clear domain prefixes for commands and workflows:

  ```plaintext
  infrastructure:*
  platform:*
  operations:*
  docs:*
  ```

- Use lowercase Taskfile variables:
  ```bash
  task tofu:plan stack=proxmox
  ```

## Taskfile

`Taskfile.yml` is the main human entrypoint.

- Taskfile tasks should be thin orchestration wrappers.
- Complex logic belongs in scripts or tools.

**Preferred shape:**

```yaml
operations:health:
  desc: Run homelab health checks
  cmds:
    - ./operations/scripts/health.sh
```

- Avoid embedding long shell scripts directly in YAML.
- Public tasks should have `desc`.

## Shell

Operational shell scripts use Bash.

**Standard header:**

```bash
#!/usr/bin/env bash
set -euo pipefail
```

**Preferred helpers:**

```bash
log() {
  printf '[info] %s\n' "$*"
}

die() {
  printf '[error] %s\n' "$*" >&2
  exit 1
}
```

- Shell scripts should use quoted variables, clear functions, repo-relative paths, and predictable output.
- Shell formatting and validation tools:
  ```plaintext
  shfmt
  shellcheck
  ```

## Python

Python is reserved for cases where shell becomes fragile or unreadable.

**Good uses:**

- JSON processing
- YAML processing
- API interaction
- Structured validation
- Report generation
- Non-trivial data transformation

- Operational Python tools belong under:

  ```plaintext
  operations/tools/
  ```

- Prefer the standard library unless a dependency has a clear benefit.

## OpenTofu

OpenTofu is used for declarative infrastructure state.

**Typical layout:**

```plaintext
infrastructure/opentofu/
├── modules/
└── stacks/
```

**Conventions:**

- Reusable logic in `modules/`
- Environment-specific state in `stacks/`
- Explicit variables
- Explicit outputs
- Minimal abstraction
- Formatted with `tofu fmt`
- Validated with `tofu validate`

- State files and plan files are sensitive.

## Ansible

Ansible is used for host configuration and lifecycle tasks.

**Typical layout:**

```plaintext
infrastructure/ansible/
├── inventories/
├── playbooks/
└── roles/
```

**Conventions:**

- Focused roles
- Readable playbooks
- Clear task names
- Idempotent modules when available
- `changed_when` and `failed_when` for command tasks
- Linted with `ansible-lint`

## Kubernetes and Platform

Kubernetes and platform services belong to the Platform domain.

**Conventions:**

- Declarative manifests
- Reconciliation over manual mutation
- Clear separation between cluster services and applications
- Validation before deployment
- No Kubernetes manifests under `infrastructure/`

## Secrets

Secrets are encrypted with SOPS.

**Secrets conventions:**

- No plaintext secrets
- No real tokens in examples
- No secrets in logs, docs, plans, or generated output
- Predictable domain-specific secret locations
- Placeholders for documentation examples

**Accepted placeholders:**

```plaintext
REDACTED
example
changeme
your-token-here
```

**Sensitive artifacts include:**

- OpenTofu state
- OpenTofu plans
- kubeconfigs
- Talos configs
- Generated credentials

## Documentation

Documentation is part of the system.

**Suggested structure:**

```plaintext
docs/architecture/
docs/infrastructure/
docs/platform/
docs/operations/
```

**Documentation types:**

- Architecture explains **why**
- Infrastructure docs explain **what exists**
- Platform docs explain **what runs on Kubernetes**
- Operations docs explain **how to operate, recover, and troubleshoot**

- Runbooks should be procedural and command-oriented.

## Commits

**Commit format:**

```plaintext
<domain>: <change>
```

**Examples:**

```plaintext
infrastructure: add proxmox talos vm module
infrastructure: configure cloudflare tunnel access
platform: add external-secrets bootstrap
operations: add tofu stack validation script
docs: document node replacement runbook
taskfile: add infrastructure plan command
secrets: add encrypted opentofu credentials
```

- Commit subjects are lowercase, concise, imperative, and do not end with a period.
- Unrelated changes should be separate commits.

## Pull Requests

**PR title format:**

```plaintext
<domain>: <summary>
```

**Preferred PR body:**

```markdown
## Summary

- What changed
- Why it changed

## Validation

- Commands run
- Plans generated
- Checks performed

## Risk

- Low / Medium / High
- Rollback or recovery notes if relevant
```

- PRs should be scoped and reviewable.
- Documentation-only PRs should say so explicitly.
- Infrastructure PRs should include plan summaries when practical.
- Operations PRs should include example command usage when practical.

## Validation

Use the narrowest relevant validation for the changed files.

**Common checks:**

```bash
nix flake check
treefmt --check .
tofu fmt -check
tofu validate
ansible-lint
shellcheck
shfmt -d
yamllint
kubeconform
```

- Validation commands should be reproducible from the repository root where practical.

## Safety

The repository favors inspection, formatting, validation, and planning before mutation.

**High-risk operations include:**

- `infrastructure apply`
- `infrastructure destroy`
- Kubernetes `apply`/`delete`
- VM deletion
- Disk wiping
- Storage pool changes
- DNS record deletion
- Secret deletion
- Production credential rotation
- Backup pruning

- Destructive workflows should be explicit, documented, and hard to trigger accidentally.

## Final Principle

Optimize for the future maintainer who has not touched the lab in three months.

The best change is **obvious, safe, boring, documented where needed, and easy to recover from**.
