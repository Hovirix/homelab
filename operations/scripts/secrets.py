#!/usr/bin/env python3

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

from secretspec import resolve

ROOT = Path(__file__).resolve().parents[2]
SECRETS_FILE = ROOT / "secrets/production.sops.env"


def run(*args, input=None, check=True):
    return subprocess.run(
        args,
        input=input,
        check=check,
        text=True,
        capture_output=True,
        cwd=ROOT,
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


def encrypted_values(names):
    values = {}
    pattern = re.compile(r"^([A-Z][A-Z0-9_]*)=(ENC\[.+\])$")

    for line in SECRETS_FILE.read_text().splitlines():
        match = pattern.fullmatch(line)

        if match:
            values[match.group(1)] = match.group(2)

    missing = sorted(set(names) - values.keys())

    if missing:
        raise RuntimeError(f"Missing encrypted SOPS entries for: {', '.join(missing)}")

    return values


def versioned_name(name, encrypted_value):
    version = hashlib.sha256(encrypted_value.encode()).hexdigest()[:12]
    return f"{name.lower()}_{version}"


def create(name, value):
    run("docker", "secret", "create", name.lower(), "-", input=value)
    print(f"Creating secret: {name}")


def clean(names):
    referenced = set()

    for service in run("docker", "service", "ls", "-q").stdout.splitlines():
        spec = json.loads(run("docker", "service", "inspect", service).stdout)[0]
        secrets = spec["Spec"]["TaskTemplate"]["ContainerSpec"].get("Secrets", [])
        referenced.update(secret["SecretName"] for secret in secrets)

    pattern = re.compile(
        rf"^(?:{'|'.join(re.escape(name.lower()) for name in names)})_[a-f0-9]{{12}}$"
    )

    for name in run(
        "docker", "secret", "ls", "--format", "{{.Name}}"
    ).stdout.splitlines():
        if pattern.fullmatch(name) and name not in referenced:
            run("docker", "secret", "rm", name)
            print(f"Removing secret: {name}")


def render(versions):
    for stack in sorted(ROOT.glob("platform/**/stack.yml")):
        original = stack.read_text()
        rendered = original

        for name, version in versions.items():
            rendered = re.sub(
                rf"^(  {name}:\n    external: true\n)(?:    name: [^\n]*\n)?",
                rf'\1    name: "{version}"\n',
                rendered,
                flags=re.MULTILINE,
            )

        if rendered != original:
            stack.write_text(rendered)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--render", action="store_true")
    parser.add_argument("--clean", action="store_true")
    args = parser.parse_args()

    secrets = resolve(
        profile="production",
        scope="swarm",
        reason="reconcile Docker Swarm secrets",
    ).fields()
    encrypted = encrypted_values(secrets)
    versions = {name.lower(): versioned_name(name, encrypted[name]) for name in secrets}

    if args.render:
        render(versions)
        return

    if args.clean:
        clean(secrets)
        return

    for name, value in secrets.items():
        if not exists(versions[name.lower()]):
            create(versions[name.lower()], value)


if __name__ == "__main__":
    main()
