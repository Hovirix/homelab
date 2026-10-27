---
name: backup-recovery
description: Use for HX Lab data loss, corruption, PostgreSQL incidents, ZFS recovery, and recovery planning.
---

# Backup Recovery

Advisory only: guide the user; never execute backup, restore, rollback, SSH, ZFS, Docker, database, or Proxmox commands. Give one step at a time and ask for its output before proceeding. Never claim recovery success from an exit code alone.

## Context

- Three Swarm nodes share PVE storage: `/rpool/swarm/DATASET` on PVE is `/var/mnt/swarm/DATASET` in guests.
- Sanoid is configured for 24 hourly local snapshots. Borgmatic snapshots `paperless`, `postgres`, and `vaultwarden` to Hetzner Storage Box. Configuration does not prove recovery points exist or are healthy.
- Repository-root sources: `operations/taskfiles/backup-restore.yml`, `operations/scripts/swarm.sh`, and `infrastructure/ansible/roles/backup/templates/restore.sh.j2`. PVE runs the deployed `/usr/local/sbin/restore`; local edits require deployment via `task pve:apply` before use.

## Choose the recovery

1. Ask what is damaged, the last known good time, and when damage likely began. Confirm timezone.
2. Identify the smallest scope and its dependent workloads. Prefer selective files or application/database recovery over whole datasets.
3. Request evidence of available recovery points. For local snapshots, ask the user to run `zfs list -t snapshot -r rpool/swarm` on PVE. Choose a confirmed point before the damage, not simply the newest.
4. For PostgreSQL, distinguish rows/tables, one database, and the whole instance. A filesystem restore is not proof of database consistency; verify available logical backups separately and do not assume WAL/PITR exists. Paperless and Vaultwarden also store state in PostgreSQL: rolling back their files alone may not match their database state.

## Off-site restore

1. Pause deployments. Identify and remove affected stacks and dependencies, one stack per command: `task services:rm -- STACK`. For PostgreSQL, include all database clients and the `postgres` stack; do not stop unrelated stacks without need.
2. Run `task restore:offsite -- DATASET...`, e.g. `task restore:offsite -- paperless postgres`. These are dataset names, not necessarily stack names. The check rejects writable mount overlaps and unreachable nodes across all three hosts; read-only monitoring mounts are allowed. It does not lock out later deployments.
3. Select one archive containing all selected datasets, confirmed before the incident. Dataset selection is already supplied; another dataset prompt indicates an outdated PVE script—cancel and check deployment.
4. The script checks the archive and stages every selected dataset at `/rpool/restore/DATASET-TIMESTAMP-RANDOM/DATASET`. The nested dataset directory preserves archived ownership and permissions. Extraction failures stop before live copying.
5. Inspect the printed source/destination pairs. Type `RESTORE` only with affected workloads stopped: `rsync --delete` overwrites live files and removes files absent from the backup; `.zfs` is excluded. Multi-dataset copying is not atomic.
6. Silent rsync followed by SSH closing without a Task error is expected, not proof of application recovery. On any error, keep workloads stopped: live data may already be partly replaced. Inspect the error and staged data before retrying; do not delete snapshots to fix `.zfs` errors.
7. After successful copying, `task deploy` redeploys all configured stacks. Verify `task status`, affected logs (`task services:logs -- SERVICE`), application health, and the specific recovered data. Verify PostgreSQL recovery before accepting dependent applications as recovered.

## Other paths

- `task restore:extract`: select an archive and dataset; stage files only, without stopping workloads or replacing live data. Plan selective copying separately and stop writers before applying it.
- `task restore:local`: stop affected workloads first, then select a dataset and snapshot. Typing `ROLLBACK` discards newer writes and destroys newer snapshots. There is no automatic Swarm safety check on this path.
- Leave staging cleanup until recovery is verified; do not remove live datasets or snapshots as cleanup.
