## Repository

HX Lab is a personal self-hosted DevSecOps platform.

This repository is the source of truth for infrastructure, platform, operations, and documentation.

Keep changes simple, boring, readable, reviewable, and recoverable.

## Work Routing

The repository is divided into three domains.

### Infrastructure

Infrastructure defines the state required before the platform can run.

Route infrastructure state, provisioning, networking, compute, storage, and node lifecycle work to the **Infrastructure Agent**.

### Platform

Platform defines Kubernetes and platform services running on top of infrastructure.

Route platform state, cluster services, application delivery, and Kubernetes configuration work to the **Platform Agent**.

### Operations

Operations defines how the lab is run.

Route automation, checks, maintenance, backup, restore, troubleshooting, runbooks, and human entrypoints to the **Automation Agent**.

### Tools

Tools defines repository-level developer tooling and validation.

Route root flake wiring, dev shells, formatters, linters, checks, and helper script plumbing to the **Automation Agent**.

### Documentation

Documentation explains the engineering architecture, infrastructure deployed, platform states and foundations, and operations.

Route documentation writing, structure, cleanup, and knowledge capture to the **Documenter Agent**.

### Security

Security is a review function.

Route security, exposure, access, secrets, identity, permissions, and safety review to the **Security Agent**.

## Boundary Model

Infrastructure defines infrastructure state.

Platform defines platform state.

Operations defines operational workflows.

Documentation explains the system.

Security reviews risk.

If work crosses domains, keep changes separated and hand off to the correct agent.

## Principles

- Git is the source of truth.
- Configuration is declared as code.
- Secrets are encrypted.
- Changes are small and reviewable.
- Prefer explicit state over implicit behavior.
- Prefer readable code over clever code.
- Prefer local reproducibility.
- Prefer safe defaults.
- Prefer documentation close to the thing it explains.

## Code Style

Code should be boring.

Prefer:

- Small files
- Clear names
- Explicit inputs
- Explicit outputs
- Minimal abstraction
- Comments only for non-obvious decisions

Avoid:

- Clever abstractions
- Hidden side effects
- Large inline logic
- Broad generic helpers without a real need
- Duplicated configuration
- Undocumented behavior

## Naming

- Use lowercase names where practical.
- Use hyphens for human-facing names and documentation paths.
- Use underscores where the tool ecosystem expects them.
- Use clear domain prefixes for commands and workflows.
- Use lowercase Taskfile variables.

Examples:

```plaintext
infrastructure:*
platform:*
operations:*
docs:*
```

## Commits

Commit format:

```plaintext
<type>(<domain>): <change>
```

Examples:

```plaintext
feat(infrastructure): add opentofu talos module
fix(platform): correct ingress for monitoring
chore(operations): update health check task
docs(operations): document backup restore workflow
```

- Commit subjects are lowercase, concise, imperative, and do not end with a period.
- Unrelated changes should be separate commits.

Examples for repo tooling:

```plaintext
chore(tools): add flake checks
chore(tools): refactor dev shells
```

## Pull Requests

PR title format:

```plaintext
<domain>: <summary>
```

Preferred PR body:

```md
## Summary

- What changed
- Why it changed

## Risk

- Low / Medium / High
- Rollback or recovery notes if relevant
```

- PRs should be scoped and reviewable.
- Documentation-only PRs should say so explicitly.
- Safety-sensitive PRs should request Security Agent review.

## Issues

Issues should be actionable.

Prefer including:

- Problem or goal
- Affected domain
- Relevant paths
- Expected outcome
- Risk or safety notes when relevant

## Safety

For security, exposure, access, secrets, identity, permissions, or destructive workflow concerns, route review to the **Security Agent**.

High-risk changes should be explicit, documented, and reviewed before execution.

## Final Principle

Optimize for the future maintainer who has not touched the lab in three months.

The best change is obvious, safe, boring, documented where needed, and easy to recover from.
