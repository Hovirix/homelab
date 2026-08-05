---
name: docker
description: Use for Docker and Docker Swarm work under platform/** and operations workflows that render, validate, or manage containers, stacks, services, networks, volumes, secrets, configs, ingress, and health checks.
---

# Docker

Use this for Docker Swarm platform desired state under `platform/**` and Docker-related operational workflows under `operations/**`.

Read the relevant stack, compose, service, config, secret reference, Taskfile, or script before changing behavior. Follow the local conventions in the touched files.

Use upstream docs when Docker behavior matters:

- Docker docs: https://docs.docker.com/
- Docker Engine: https://docs.docker.com/engine/
- Docker Swarm: https://docs.docker.com/engine/swarm/
- Compose file reference: https://docs.docker.com/reference/compose-file/

Use the configured Docker docs MCP when behavior is version-sensitive or security-sensitive.

Do not assume a service, network, secret, ingress route, backup path, observability stack, PostgreSQL instance, or high-availability behavior exists unless repository files implement it.

For stateful services, identify placement, persistent data, backup/restore behavior, upgrade behavior, health checks, and failure behavior.

Never deploy stacks, mutate services, initialize or leave Swarm, restart services, or claim runtime health without explicit authorization and runtime evidence.

Validation should prefer local rendering and static checks. Rendering proves syntax and compatibility, not deployment success.
