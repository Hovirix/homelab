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
    return run("docker", "secret", "inspect", name.lower(), check=False).returncode == 0


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
        if exists(name) and changed(name):
            stop(name)
            remove(name)
            create(name, value)

        else:
            create(name, value)


if __name__ == "__main__":
    main()
