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


def refusal_message(blocked):
    details = ", ".join(
        f"{name} (consumers: {', '.join(users) or 'none'})" for name, users in blocked
    )
    return (
        f"Refusing secret changes: {details}. "
        "An explicit tested rotation workflow is required."
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

    plan = []
    blocked = []
    for name, value in secrets.items():
        present = exists(name)
        is_changed = present and changed(name)
        users = services_using(name) if present else []
        plan.append((name, value, present, is_changed))
        if is_changed and (name in STATEFUL_SECRETS or users):
            blocked.append((name, users))

    if blocked:
        print(refusal_message(blocked), file=sys.stderr)
        raise SystemExit(1)

    for name, value, present, is_changed in plan:
        if not present:
            create(name, value)
        elif is_changed:
            remove(name)
            create(name, value)


if __name__ == "__main__":
    main()
