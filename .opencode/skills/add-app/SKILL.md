---
name: add-app
description: Use when adding a new app or service to HX Lab, such as "add Miniflux".
---

# Add an application

1. Read the application's official documentation for its image, supported version, deployment, health check, database, and authentication settings. Verify exact environment variables, secret-file support, OIDC issuer and callback URLs; do not guess. Read the relevant existing stacks and integrations before editing.

2. Require Authentik SSO and disable regular/local login. Use the `question` tool only for decisions that cannot be inferred from the request or repository: hostname, who gets admin access, persistence/backup requirements, or incompatible upstream choices. If the app cannot support SSO-only authentication, stop and report the incompatibility rather than enable local fallback.

3. Add the smallest working stack under `platform/applications/<app>/stack.yml` and register it in `operations/taskfiles/services.yml`. Follow existing Swarm conventions: versioned digest-pinned image, external networks and secrets, Traefik labels, health check, rollback, and no published host ports. Add dependencies only when required by the app.

4. For each needed secret, update `secretspec.toml` under `[profiles.production]` and `[scopes.swarm]`, using the existing generation/composition conventions, and reference its `/run/secrets/` file in the stack using upstream `_FILE` options where available. For PostgreSQL URLs, use a composed secret and URL-safe password (or an upstream-supported non-URL connection format). Secrets are delivered automatically by the existing deployment workflow; do not add manual secret-deployment steps. Never invent ciphertext-derived secret names or commit plaintext. `operations/scripts/secrets.py` renders version names during the approved deployment workflow; do not run it just to fill in names.

5. If using PostgreSQL, update `platform/data/postgres/configs/postgres-reconcile.sh`, its reconcile service secrets in `platform/data/postgres/stack.yml`, and the matching database/role rule in `platform/data/postgres/configs/pg_hba.conf`. Bump affected Swarm config names in the stack when changing immutable configs.

6. Create an Authentik provider/application blueprint under `platform/identity/blueprints/`, mount it and its client secrets in `platform/identity/stack.yml`, and update `memberships.yaml` for the agreed group access. Match upstream callback, scopes, account creation, and admin mapping so the intended users can sign in with SSO from the first deployment. Bump the changed blueprint's Swarm config name. Disable regular/local login using the documented upstream setting; do not add local-login bootstrap credentials.

7. For public ingress, add the hostname to `infrastructure/opentofu/stacks/cloudflare/locals.tf`. If the app needs filesystem state, configure its ZFS dataset in `infrastructure/ansible/roles/zfs/tasks/main.yml`, the VM mount directory in `infrastructure/opentofu/stacks/proxmox/fcos/common/etc/tmpfiles.d/swarm.conf`, and an appropriate bind mount; include it in `infrastructure/ansible/roles/backup/templates/borgmatic.yaml.j2` if it needs off-site backup. Database-only apps already use the shared PostgreSQL backup; do not add an empty dataset. For an exposed app, add an HTTPS probe in `platform/observability/configs/alloy/blackbox.alloy` and its missing-probe expression in `platform/observability/configs/grafana/provisioning/alerting/blackbox.yml`.

8. Run only relevant checks: `docker stack config -c <new stack>` and changed stacks, `conftest test --quiet --policy security/policy <new stack>` and changed stacks, plus applicable formatting/lint checks. Do not deploy or apply infrastructure unless explicitly requested. Distinguish static checks from live verification.

9. If new images introduce security blockers, load `assess-image-risk` and follow its assessment, compact table, and approval rules. Adding a service does not authorize risk acceptance or exceptions; keep the CI gate and require explicit approval for scoped exceptions. Missing scans are unverified, not clean.

## Output

Always finish with these headings, in order; use `None` where appropriate:

- **Changed:** Files and behavior added.
- **Checks:** Checks run and their results, or why they could not run.
- **Manual steps:** Only actions not already automated by the repository, including required infrastructure applies and any unavoidable SSO/admin setup. Do not include secret deployment. Never request or display secret values.
- **Unverified:** Runtime behavior not confirmed, especially login, backups, and HTTPS availability.
