---
name: ansible
description: Use for Ansible work under infrastructure/ansible/**, especially Proxmox host and datacenter configuration.
---

# Ansible

Use this for changes under `infrastructure/ansible/**`.

Read the relevant playbook, role, defaults, variables, templates, and inventory before changing behavior. Follow the patterns already present in the touched role or playbook.

Use upstream docs when module behavior, idempotence, check mode, handlers, privilege behavior, or collection semantics matter:

- Ansible docs: https://docs.ansible.com/ansible/latest/
- Ansible built-in modules: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/
- community.general collection: https://docs.ansible.com/ansible/latest/collections/community/general/

In this repo, Ansible is for Proxmox host and datacenter configuration. Do not extend it into Fedora CoreOS guest mutation or Docker Swarm service management.

Prefer idempotent modules. When command tasks are necessary, use explicit state checks, `changed_when`, `failed_when`, and `run_once` where appropriate.

Do not decrypt or print secrets. Treat direct playbook execution, remote access, restarts, and destructive changes as operations that need explicit user authorization.

Validation should use linting and syntax checks where available. Report check-mode limitations instead of implying an apply is safe.
