# TrueNAS SCALE Setup Runbook

Start here after TrueNAS SCALE is installed and the web UI is reachable.

This runbook configures TrueNAS as an SFTP target for Restic laptop backups. Do not store passwords, SMTP credentials, Restic passwords, private keys, or recovery keys in this repository.

## Target Configuration

| Area              | Value                                                                  |
| ----------------- | ---------------------------------------------------------------------- |
| Hostname          | `truenas.home.hovirix.dev`                                             |
| Pool              | `tank`                                                                 |
| Dataset           | `tank/laptop_backups`                                                  |
| Dataset path      | `/mnt/tank/laptop_backups`                                             |
| Owner             | `backup-laptop`                                                        |
| Group             | `backup-laptop`                                                        |
| Access            | SSH/SFTP only                                                          |
| Restic repository | `sftp:backup-laptop@truenas.home.hovirix.dev:/mnt/tank/laptop_backups` |
| Snapshots         | Daily, 1 month retention, non-recursive                                |
| Scrub             | `tank`, Sunday 00:00, 35 day threshold                                 |
| SMTP              | Resend, `smtp.resend.com:587`, STARTTLS                                |
| Alert recipient   | `homelab@hovirix.dev`                                                  |
| Alert level       | Warning                                                                |

## Before You Start

- TrueNAS SCALE administrator credentials.
- SSH public key for the laptop backup client.
- Resend SMTP username and password.
- Restic repository password stored on the laptop backup client.
- DNS record for `truenas.home.hovirix.dev`.

## 1. Sign In

1. Open the TrueNAS SCALE web UI.
2. Sign in as an administrator.
3. Open alerts and resolve critical boot, disk, pool, or network alerts before continuing.

## 2. System Settings

1. Open **System Settings**.
2. Open **General**.
3. Set hostname to `truenas`.
4. Set the correct timezone.
5. Save changes.

## 3. Network

1. Open **Network**.
2. Confirm the active interface has the intended IP address.
3. Confirm the default gateway is set.
4. Confirm DNS servers are set.
5. From another machine, verify DNS:

```bash
getent hosts truenas.home.hovirix.dev
```

## 4. Pool `tank`

If `tank` already exists:

1. Open **Storage**.
2. Confirm pool `tank` is online.
3. Confirm the expected disks are assigned.

If `tank` does not exist:

1. Open **Storage**.
2. Create a pool named `tank`.
3. Select the intended disks.
4. Select the intended vdev layout.
5. Review the disk wipe warning.
6. Create the pool only after confirming the selected disks are correct.

## 5. Dataset `tank/laptop_backups`

1. Open **Storage**.
2. Select pool `tank`.
3. Add a dataset.
4. Set name to `laptop_backups`.
5. Leave compression inherited from the pool.
6. Do not create an SMB share.
7. Save.

## 6. Group `backup-laptop`

1. Open **Credentials**.
2. Open **Local Groups**.
3. Add group `backup-laptop`.
4. Save.

## 7. User `backup-laptop`

1. Open **Credentials**.
2. Open **Local Users**.
3. Add user `backup-laptop`.
4. Set primary group to `backup-laptop`.
5. Set the home directory inside the data pool.
6. Add the laptop backup client's SSH public key.
7. Enable SSH access.
8. Disable SMB access.
9. Disable TrueNAS web UI access.
10. Save.

Avoid password SSH for this account unless temporarily needed for troubleshooting.

## 8. Dataset Ownership

1. Open **Storage**.
2. Select `tank/laptop_backups`.
3. Open the permissions or ACL editor.
4. Set owner user to `backup-laptop`.
5. Set owner group to `backup-laptop`.
6. Apply the permissions to the dataset.
7. Do not grant access to unrelated users or groups.

## 9. SSH Service

1. Open **System Settings**.
2. Open **Services**.
3. Find **SSH**.
4. Enable public key authentication.
5. Start SSH.
6. Enable SSH start on boot.

## 10. SFTP Test

Run from the laptop backup client.

```bash
getent hosts truenas.home.hovirix.dev
```

```bash
ssh backup-laptop@truenas.home.hovirix.dev
```

```bash
sftp backup-laptop@truenas.home.hovirix.dev
```

Inside SFTP:

```text
ls /mnt/tank/laptop_backups
```

## 11. Restic Repository

Run from the laptop backup client.

```bash
export RESTIC_REPOSITORY='sftp:backup-laptop@truenas.home.hovirix.dev:/mnt/tank/laptop_backups'
```

Set the Restic password using the laptop backup client's secret mechanism.

Initialize once:

```bash
restic init
```

Check access:

```bash
restic snapshots
```

## 12. Snapshots

1. Open **Data Protection**.
2. Open **Periodic Snapshot Tasks**.
3. Add a task for `tank/laptop_backups`.
4. Set schedule to daily.
5. Set retention to 1 month.
6. Disable recursive snapshots.
7. Enable the task.
8. Save.

## 13. Scrub

1. Open **Data Protection**.
2. Open **Scrub Tasks**.
3. Add or edit the task for pool `tank`.
4. Set schedule to Sunday at 00:00.
5. Set threshold to 35 days.
6. Enable the task.
7. Save.

## 14. SMTP Email

1. Open **System Settings**.
2. Open email settings.
3. Set SMTP server to `smtp.resend.com`.
4. Set port to `587`.
5. Set security to STARTTLS.
6. Enable SMTP authentication.
7. Enter the Resend SMTP username and password from the secret store.
8. Set the administrator email address.
9. Save.
10. Send a test email.

## 15. Alerts

1. Open alert service settings.
2. Enable email alerts.
3. Set recipient to `homelab@hovirix.dev`.
4. Set alert level to Warning.
5. Disable SNMP Trap alerting.
6. Save.
7. Send or trigger a test alert if available.

## 16. Backup Test

Run from the laptop backup client.

```bash
mkdir -p /tmp/restic-truenas-test
date > /tmp/restic-truenas-test/restore-test.txt
```

```bash
restic backup /tmp/restic-truenas-test
```

```bash
restic snapshots
```

```bash
restic check
```

## 17. Restore Test

Restore into a temporary path. Do not restore over live data.

```bash
restic snapshots
```

```bash
mkdir -p /tmp/restic-restore-test
restic restore <snapshot-id> --target /tmp/restic-restore-test
```

```bash
find /tmp/restic-restore-test -name restore-test.txt -print
```

```bash
rm -rf /tmp/restic-restore-test /tmp/restic-truenas-test
```

Record the restore test:

| Date         | Snapshot ID     | Result        | Notes     |
| ------------ | --------------- | ------------- | --------- |
| `YYYY-MM-DD` | `<snapshot-id>` | `<pass/fail>` | `<notes>` |

## 18. Final Checklist

- Pool `tank` is online.
- Dataset `tank/laptop_backups` exists.
- Dataset owner and group are `backup-laptop`.
- SSH is running and enabled at boot.
- `backup-laptop` can access SFTP with public key authentication.
- `backup-laptop` does not have SMB or TrueNAS UI access.
- Restic backup succeeds.
- Restic restore test succeeds.
- Daily non-recursive snapshots are enabled with 1 month retention.
- Scrub task for `tank` is enabled.
- SMTP test email succeeds.
- Warning alerts go to `homelab@hovirix.dev`.
- SNMP Trap alerting is disabled.

## 19. Routine Checks

- Review TrueNAS alerts.
- Check pool `tank` health.
- Check recent snapshots for `tank/laptop_backups`.
- Review the latest scrub result.
- Run `restic snapshots` from the laptop backup client.
- Run `restic check` on a regular schedule.
- Repeat the restore test after major TrueNAS, laptop, network, or backup changes.

## 20. Future Datasets

| Dataset                | Purpose                   | Status  |
| ---------------------- | ------------------------- | ------- |
| `tank/proxmox_backups` | Proxmox backup storage    | Planned |
| `tank/archive`         | Long-term archive storage | Planned |
| `tank/media`           | Optional media storage    | Planned |

For each new dataset:

1. Create it under `tank`.
2. Set ownership and permissions.
3. Enable only required access methods.
4. Add snapshots if it needs local recovery points.
5. Validate client access.
6. Test restore if the data matters.
7. Update this runbook.

## Troubleshooting

SFTP failure:

- Check SSH service status.
- Check the SSH public key on `backup-laptop`.
- Check that SSH access is enabled for `backup-laptop`.
- Check DNS for `truenas.home.hovirix.dev`.
- Check firewall rules between the client and TrueNAS.

Restic write failure:

- Check ownership of `/mnt/tank/laptop_backups`.
- Check the repository path.
- Check free space on `tank`.

Email alert failure:

- Check `smtp.resend.com` and port `587`.
- Check STARTTLS.
- Check SMTP authentication.
- Check Resend credentials.
- Check TrueNAS DNS and outbound internet access.

## Safety Notes

- Creating a pool can wipe disks.
- ZFS snapshots are not an offsite backup.
- Restore into a temporary path before replacing live data.
- Keep the Restic repository password outside Git.
- Keep `backup-laptop` limited to backup access.
- Treat failed scrubs, checksum errors, SMART alerts, and degraded pools as urgent.
