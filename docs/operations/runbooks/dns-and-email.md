# DNS and Email

Start here when changing DNS rewrites or TrueNAS email alerts.

## Source Paths

- `docs/infrastructure/opentofu/stacks/adguardhome.md`
- `docs/infrastructure/opentofu/index.md`
- `docs/operations/runbooks/truenas.md`
- `infrastructure/opentofu/stacks/prod/adguardhome/main.tf`

## Current State

- AdGuard Home manages rewrites for `pve1.home.hovirix.dev`, `pve2.home.hovirix.dev`, `pve3.home.hovirix.dev`, and `truenas.home.hovirix.dev`.
- Current answers are `10.20.0.11`, `10.20.0.12`, `10.20.0.13`, and `10.30.0.106`.
- TrueNAS sends alerts through Resend SMTP at `smtp.resend.com:587` with STARTTLS.
- Proxmox SMTP notifications use the same Resend SMTP relay through Ansible.
- TrueNAS alert mail goes to `homelab@hovirix.dev`.

## DNS Rewrites

1. Edit `infrastructure/opentofu/stacks/prod/adguardhome/main.tf`.
2. Update the `dns_records` map.
3. Run `task tofu:plan stack=adguardhome`.
4. Review the plan for only the intended rewrite changes.
5. Run `task tofu:apply stack=adguardhome`.
6. Verify name resolution from a client machine.

```bash
getent hosts pve1.home.hovirix.dev
```

## Email Alerts

1. Follow the TrueNAS runbook for SMTP and alert settings.
2. Keep SMTP credentials out of the repository.
3. Confirm the alert recipient is `homelab@hovirix.dev`.
4. Send a test message after changing the SMTP settings.
5. Trigger or send a test alert if the UI supports it.

## Notes

- DNS changes belong in OpenTofu, not in manual AdGuard edits.
- Email credentials belong in the secret store only.
