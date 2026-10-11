#!/usr/bin/env python3

import json
import subprocess
import sys
from pathlib import Path

from secretspec import resolve

ROOT = Path(__file__).resolve().parents[2]
SECRETS_FILE = Path("secrets/production.sops.env")

# Postgres credentials are stateful: the database keeps the password, so the
# role must change in Postgres before dependents restart with a new secret.
STATEFUL_SECRETS = frozenset(
    {
        "POSTGRES_SUPERUSER_PASSWORD",
        "POSTGRES_AUTHENTIK_PASSWORD",
        "POSTGRES_PAPERLESS_PASSWORD",
    }
)


def run(*args, input=None, check=True):
    return subprocess.run(
        args, input=input, check=check, text=True, capture_output=True, cwd=ROOT
    )


def exists(name):
    result = run("docker", "secret", "inspect", name.lower(), check=False)

    if result.returncode == 0:
        return True

    if (
        "not found" in result.stderr.lower()
        or "no such secret" in result.stderr.lower()
    ):
        return False

    raise RuntimeError(
        f"Could not inspect Docker secret {name.lower()}: {result.stderr.strip()}"
    )


def changed(name):
    diff = run("git", "diff", "-U0", "HEAD", "--", SECRETS_FILE, check=False).stdout

    return any(
        line.startswith((f"+{name}=", f"-{name}=")) for line in diff.splitlines()
    )


def services_using(name):
    users = []
    for service in run("docker", "service", "ls", "-q").stdout.splitlines():
        spec = json.loads(run("docker", "service", "inspect", service).stdout)[0]
        secrets = spec["Spec"]["TaskTemplate"]["ContainerSpec"].get("Secrets", [])

        if name.lower() in {secret["SecretName"] for secret in secrets}:
            users.append(spec["Spec"].get("Name", service))

    return sorted(users)


def rotation_order(name):
    if name == "POSTGRES_SUPERUSER_PASSWORD":
        return (0, name)
    if name in STATEFUL_SECRETS:
        return (1, name)
    return (2, name)


def refusal_message(refused):
    details = ", ".join(
        f"{name} (used by: {', '.join(users)})" for name, users in refused
    )
    ordered = ", ".join(name for name, _ in refused)
    return (
        f"Refusing to rotate in-use Swarm secret(s): {details}.\n"
        "Role passwords must update in Postgres before dependents "
        "receive new secrets.\n"
        "Ordered manual procedure (no `docker service rm`):\n"
        "  1. Confirm Postgres backup/restore path.\n"
        "  2. Update database roles first via the postgres reconcile job "
        "with the current superuser credential, then verify with "
        "pg_isready and a superuser login.\n"
        f"  3. Rotate in order ({ordered}): detach with "
        "`docker service update --secret-rm`, `docker secret rm`, "
        "`docker secret create`, re-attach with "
        "`docker service update --secret-add`.\n"
        "  4. Redeploy stacks in order (postgres, authentik, paperless) "
        "and verify `docker service ls` plus dependent health."
    )


def remove(name):
    run("docker", "secret", "rm", name.lower())
    print(f"Removing secret: {name}")


def create(name, value):
    run("docker", "secret", "create", name.lower(), "-", input=value)
    print(f"Creating secret: {name}")


def main():
    secrets = resolve(
        profile="production",
        scope="swarm",
        reason="reconcile Docker Swarm secrets",
    ).fields()

    refused = []
    for name, value in secrets.items():
        if not exists(name):
            create(name, value)

        elif changed(name):
            users = services_using(name)
            if users:
                refused.append((name, users))
                continue
            remove(name)
            create(name, value)

    if refused:
        refused.sort(key=lambda item: rotation_order(item[0]))
        print(refusal_message(refused), file=sys.stderr)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
