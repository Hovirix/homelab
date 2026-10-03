#!/usr/bin/env python3

import json
import subprocess
from pathlib import Path

from secretspec import resolve

ROOT = Path(__file__).resolve().parents[2]
SECRETS_FILE = Path("secrets/production.sops.env")


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


def stop(name):
    for service in run("docker", "service", "ls", "-q").stdout.splitlines():
        spec = json.loads(run("docker", "service", "inspect", service).stdout)[0]
        secrets = spec["Spec"]["TaskTemplate"]["ContainerSpec"].get("Secrets", [])

        if name.lower() in {secret["SecretName"] for secret in secrets}:
            run("docker", "service", "rm", service)


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

    for name, value in secrets.items():
        if not exists(name):
            create(name, value)

        elif changed(name):
            stop(name)
            remove(name)
            create(name, value)


if __name__ == "__main__":
    main()
