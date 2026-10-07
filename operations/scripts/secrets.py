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


def main():
    secrets = resolve(
        profile="production",
        scope="swarm",
        reason="reconcile Docker Swarm secrets",
    ).fields()
    diff = run("git", "diff", "-U0", "HEAD", "--", SECRETS_FILE, check=False).stdout

    for name, value in secrets.items():
        lowered = name.lower()
        inspected = run("docker", "secret", "inspect", lowered, check=False)

        if inspected.returncode != 0:
            if (
                "not found" not in inspected.stderr.lower()
                and "no such secret" not in inspected.stderr.lower()
            ):
                raise RuntimeError(
                    f"Could not inspect Docker secret {lowered}: {inspected.stderr.strip()}"
                )
        elif not any(
            line.startswith((f"+{name}=", f"-{name}=")) for line in diff.splitlines()
        ):
            continue

        if inspected.returncode == 0:
            for service in run("docker", "service", "ls", "-q").stdout.splitlines():
                spec = json.loads(run("docker", "service", "inspect", service).stdout)[
                    0
                ]
                attached = spec["Spec"]["TaskTemplate"]["ContainerSpec"].get(
                    "Secrets", []
                )

                if lowered in {secret["SecretName"] for secret in attached}:
                    run("docker", "service", "rm", service)

            run("docker", "secret", "rm", lowered)
            print(f"Removing secret: {name}")

        run("docker", "secret", "create", lowered, "-", input=value)
        print(f"Creating secret: {name}")


if __name__ == "__main__":
    main()
