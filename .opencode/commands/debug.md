---
description: Debug any HX Lab problem by exploring repository desired state and observing runtime with read-only commands.
agent: plan
---

$ARGUMENTS

General-purpose debug. Adapt the entire approach to what the arguments describe.

1. Interpret the symptom: service, stack, network, node, ingress, backup, container, config, provider, workflow, or unknown.
2. Map it to a domain and explore the matching repository paths first (`platform/**`, `operations/**`, `infrastructure/**`, `Taskfile.yml`) using native `read`, `glob`, and `grep`. Load the `docker` skill when containers or Swarm are involved.
3. Observe runtime only with read-only commands chosen by what the arguments point to:
   - Swarm/service: `docker service ls`, `docker service ps`, `docker service logs`, `docker node ls`, or `task platform:logs DOMAIN=<domain> SERVICE=<service>` when a specific service is known
   - Infrastructure: OpenTofu state/plan output, Ansible facts, approved runtime evidence
   - Operations/CI: workflow logs and Taskfile entries
4. Compare desired state vs observed runtime to isolate the cause. Separate symptoms, observed evidence, hypotheses, and next checks.
5. Propose the least invasive next checks before any mutation.

Never restart services, deploy stacks, apply infrastructure, initialize or leave Swarm, decrypt secrets, or claim root cause without evidence.
