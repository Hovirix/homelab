---
name: backup-recovery
description: Use for HX Lab data loss, corruption, PostgreSQL incidents, ZFS recovery, and recovery planning.
---

# Backup Recovery

This skill is advisory only. Do not execute backup, restore, rollback, database recovery, SSH, ZFS, Docker, or Proxmox commands.

Use repository configuration and evidence supplied by the user. Repository code describes intended recovery mechanisms, not which recovery points currently exist.

## Recovery Process

1. Establish the incident window: last known good, suspected incident start, and detection time.
2. Identify the smallest affected scope: file, directory, application data, database rows/tables, database, service, dataset, or host storage.
3. Select the newest recovery point clearly before the incident window.
4. Confirm availability through user-provided evidence before recommending it.
5. Recommend the smallest safe recovery method. Do not restore unrelated data.

Do not choose a recovery point simply because it is newest. State uncertainty rather than presenting an inferred incident time or recovery point as confirmed.

## Implemented Recovery Mechanisms

- `rpool/swarm` has hourly local Proxmox ZFS snapshots named `auto-YYYY-MM-DD_HH-MM` for short-term recovery.
- `task restore` is the repository restore entrypoint. It is destructive and must never be run by the agent.

If local snapshot availability is unknown, request read-only evidence such as:

```bash
zfs list -t snapshot -r rpool/swarm
```

Do not execute the command. Do not claim that a local recovery point exists or is healthy without evidence.

## Scope Selection

Prefer recovery in this order:

```text
selective file or directory recovery
application-level recovery
PostgreSQL-aware recovery
local ZFS rollback
Proxmox backup recovery
```

Before a full `rpool/swarm` rollback, warn that dependent workloads must be stopped or safely quiesced and that newer data or snapshots may be lost.

## PostgreSQL

Do not default PostgreSQL incidents to a ZFS rollback. Diagnose the database scope first and prefer rows/tables, then a database, then an instance.

The repository does not prove a PostgreSQL logical-backup, WAL, or PITR workflow. Do not imply that any database-aware backup exists. A restored filesystem does not by itself prove PostgreSQL recovery.

## Output

Return:

```text
Incident
<what failed>

Incident window
Last known good: <time>
Suspected start: <time or range>

Impact
<smallest affected scope>

Safe recovery point
<time or unknown>

Availability
<confirmed local | Proxmox backup evidence required | unknown>

Recommended approach
<smallest safe method>

Why
<short justification>

Required evidence or authorized action
<read-only evidence needed, or the user action>
```

Never claim recovery success without post-recovery evidence.
