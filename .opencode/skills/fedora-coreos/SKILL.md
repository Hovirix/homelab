---
name: fedora-coreos
description: Use for HX Lab Fedora CoreOS provisioning work involving Butane source, Ignition output, immutable host design, and Proxmox VM integration.
---

# Fedora CoreOS

Use this skill for Fedora CoreOS node provisioning under `infrastructure/opentofu/stacks/proxmox/**`.

Read the relevant Butane source, node data, generated Ignition references, VM resource, networking, storage, and systemd units before changing behavior.

Use upstream docs when schema behavior, first-boot behavior, update behavior, storage, networking, systemd, or provisioning semantics matter:

- Fedora CoreOS docs: https://docs.fedoraproject.org/en-US/fedora-coreos/
- Butane docs: https://coreos.github.io/butane/
- Ignition docs: https://coreos.github.io/ignition/
- systemd docs: https://www.freedesktop.org/software/systemd/man/latest/

Keep Butane as the human-maintained source of truth. Do not hand-edit generated Ignition as durable desired state.

Fedora CoreOS hosts should be treated as immutable container hosts. Prefer first-boot provisioning, declarative files, systemd units, storage declarations, and node replacement over SSH-based post-install mutation.

Do not normalize mutable guest management through Ansible. Ansible remains for Proxmox hosts only.

When changing users, SSH keys, sudo policy, storage, networking, or systemd units, identify node replacement impact and whether existing nodes need reprovisioning.

Validation should include strict Butane rendering where possible and OpenTofu validation of the consuming Proxmox stack. Rendering proves syntax, not successful boot.
