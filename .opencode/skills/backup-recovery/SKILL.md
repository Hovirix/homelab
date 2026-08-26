---
name: backup-recovery
description: Diagnose HX Lab data incidents, determine the last known-good time, and advise the smallest safe recovery using local Proxmox snapshots, TrueNAS disaster recovery, or PostgreSQL-aware recovery.
---

# Backup and Recovery

Use for data loss, corruption, accidental deletion, bad deployments, PostgreSQL incidents, ZFS recovery, and disaster recovery.

This skill is **advisory only**.

Never execute backup, restore, rollback, database recovery, SSH, ZFS, Docker, Proxmox, or TrueNAS commands.

The agent may inspect repository configuration and analyze evidence provided by the user. For runtime state, tell the user what command or UI information is needed and analyze the returned output.

## Decision flow

```text
Incident
   ↓
When did it start?
   ↓
What is affected?
   ↓
What recovery point is safe?
   ↓
Is it available locally?
   ├─ Yes → advise local recovery
   └─ No  → advise TrueNAS recovery
```

Always:

1. diagnose the incident
2. establish the incident window
3. determine the smallest affected scope
4. choose the newest recovery point clearly before the incident
5. recommend the smallest safe recovery
6. tell the user exactly what to run or select

Never perform the recovery yourself.

## Storage model

Live persistent data:

`rpool/swarm`

Backup path:

```text
rpool/swarm
    ↓ hourly Proxmox ZFS snapshot
rpool/swarm@auto-YYYY-MM-DD_HH-MM
    ↓ TrueNAS scheduled PULL over SSH
tank/backups/swarm
```

Local Proxmox snapshots are for short-term recovery.

TrueNAS is the off-host recovery layer.

TrueNAS is not runtime storage.

## 1. Diagnose the incident

Determine what failed.

Prefer the smallest scope:

```text
file
directory
application data
application
PostgreSQL rows/tables
PostgreSQL database
PostgreSQL instance
rpool/swarm
Proxmox storage/host
```

Investigate available evidence:

- symptoms
- logs supplied by the user
- deployment/change history
- timestamps
- filesystem evidence
- database symptoms
- user actions
- last known successful operation

Do not recommend rollback before understanding the incident.

Do not restore the whole dataset for an incident that can be recovered more narrowly.

## 2. Determine when

Build a timeline:

```text
last known good
      ↓
incident introduced
      ↓
incident detected
```

Choose the newest recovery point that clearly predates the incident.

Example:

```text
10:00 snapshot        safe
11:00 snapshot        safe
11:37 bad deployment
12:00 snapshot        unsafe
12:24 incident found
```

Recommendation:

`11:00`

Do not choose `12:00` simply because it is newer.

If the exact incident time is uncertain:

- state the uncertainty
- identify the suspected incident window
- choose a recovery time safely before that window

Never present an inferred time as confirmed.

## 3. Choose recovery scope

Prefer recovery in this order:

```text
selective file recovery
        ↓
application-level recovery
        ↓
PostgreSQL-aware recovery
        ↓
local ZFS rollback
        ↓
TrueNAS disaster recovery
```

Use the smallest method capable of fixing the incident.

Avoid restoring unrelated data.

## 4. Determine local availability

Local snapshots use:

`rpool/swarm@auto-%Y-%m-%d_%H-%M`

The agent must not run commands to inspect them.

If local snapshot availability is unknown, tell the user to provide the output of the repository's read-only snapshot/status workflow.

If none exists, advise a read-only inspection command such as:

```bash
zfs list -t snapshot -r rpool/swarm
```

Do not execute it.

Use the returned output to determine whether a safe local recovery point exists.

## 5. Local recovery

Use local recovery when a safe recovery point is confirmed to exist on Proxmox.

Recommend:

```bash
task restore
```

Do not run it.

Tell the user which recovery point to select.

Example recommendation:

```text
Incident
Application data became invalid after the 11:37 deployment.

When
Last known good: 11:00
Incident introduced: approximately 11:37

Impact
Application data

Recovery point
auto-2026-08-25_11-00

Availability
Confirmed local on Proxmox.

Recommended solution
Local rollback.

Why
11:00 is the newest confirmed snapshot before the incident.

Action
Run:

task restore

Select:
auto-2026-08-25_11-00
```

Before recommending a full rollback, warn that workloads using `rpool/swarm` must be stopped or safely quiesced.

If rollback could remove newer snapshots/data, warn the user before they proceed.

Never run the restore command.

## 6. Selective recovery

If only a file or directory is affected, recommend selective recovery when possible.

State:

- affected path
- safe recovery time
- why full dataset rollback is unnecessary

Do not recommend whole-`rpool/swarm` rollback unless required.

## 7. TrueNAS recovery

Use TrueNAS when:

- the safe recovery point is no longer available locally
- `rpool/swarm` is lost
- Proxmox storage failed
- the host/storage was rebuilt

The agent has **no access to TrueNAS**.

Do not claim a TrueNAS snapshot exists, is healthy, or is available.

Determine only the safe recovery time.

Example:

```text
Last known good:
11:00

Incident window:
11:37–12:10

Recommended safe recovery boundary:
11:00 or earlier
```

Then advise the user to open:

```text
TrueNAS
→ Data Protection
→ Replication Tasks
→ swarm-restore-truenas-to-pve1
```

Tell the user:

> Select the newest available snapshot at or before the recommended safe recovery time, then run the PUSH restore.

Example:

```text
Recommended safe recovery time:
2026-08-25 11:00

Action:
Open TrueNAS:

Data Protection
→ Replication Tasks
→ swarm-restore-truenas-to-pve1

Choose the newest available snapshot at or before 11:00 and run the PUSH restore.
```

Never recommend a snapshot inside or after the suspected incident window.

If the user finds no snapshot at or before the safe time, ask them to provide the available older recovery points and reassess.

Do not generate:

- TrueNAS API calls
- SSH commands
- `zfs send`
- `zfs receive`
- custom replication commands

The TrueNAS restore task remains manual.

For recovery testing, prefer restoring to:

`rpool/restore-test`

rather than overwriting live data.

## 8. PostgreSQL incidents

Do not default PostgreSQL incidents to ZFS rollback.

Diagnose the database scope first.

Prefer surgical recovery:

```text
rows/tables
    ↓
single database
    ↓
PostgreSQL instance
    ↓
filesystem recovery
    ↓
TrueNAS recovery
```

Examples:

### Deleted or incorrect rows/tables

Recommend PostgreSQL-aware surgical recovery.

Do not rollback the entire filesystem unless no narrower recovery exists.

### Single database affected

Recommend restoring only that database when possible.

### PostgreSQL instance damaged

Recommend PostgreSQL-aware instance recovery.

### Storage lost

Recommend:

```text
restore storage
      ↓
restore PostgreSQL from database-aware backup
      ↓
verify database
      ↓
recover dependent applications
```

The simple PostgreSQL backup strategy is logical backups such as `pg_dump`.

Only recommend WAL/PITR when point-in-time recovery is actually required and implemented.

Never claim PostgreSQL is recovered merely because ZFS data was restored.

## 9. Response format

Finish every incident analysis with:

```text
Incident
<what failed>

When
Last known good: <time>
Incident window: <time/range>

Impact
<smallest affected scope>

Safe recovery time
<time>

Availability
Local Proxmox | TrueNAS required | Database backup | Unknown

Recommended solution
<smallest safe recovery method>

Why
<short justification>

Action
<exact command the user should run or TrueNAS UI path they should use>
```

If evidence is insufficient, do not guess.

Instead report:

```text
Missing evidence
<what is needed>

Action
<read-only command/UI information the user should provide>
```

## Hard rules

- Advise only; never execute recovery.
- Never run operational commands.
- Diagnose before recommending rollback.
- Determine the incident window first.
- Use the newest recovery point clearly before the incident.
- Prefer the smallest recovery scope.
- Never assume the newest snapshot is safe.
- Never invent recovery points.
- Never claim local snapshot availability without evidence.
- Never claim TrueNAS snapshot availability without user evidence.
- Never invent Task commands.
- Prefer repository Task workflows over raw commands.
- Never rollback active persistent workloads.
- Never make TrueNAS a runtime dependency.
- Never put TrueNAS credentials on Proxmox.
- Never schedule TrueNAS restore replication.
- Never treat ZFS snapshots as the sole PostgreSQL recovery mechanism.
- Never claim recovery success without evidence.
