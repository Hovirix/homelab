import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

import tomllib
from secretspec import resolve

ROOT = Path(__file__).resolve().parents[2]
SECRETS_FILE = ROOT / "secrets/production.sops.env"


def run(*args, input=None):
    return subprocess.run(
        args, input=input, check=True, text=True, capture_output=True, cwd=ROOT
    ).stdout


def check(versions, existing):
    for name, version in versions.items():
        if (
            name.startswith("postgres_")
            and name.endswith("_password")
            and any(
                secret.startswith(f"{name}_") and secret != version
                for secret in existing
            )
        ):
            raise RuntimeError(f"PostgreSQL password rotation is blocked: {name}")


def sync(versions, values, existing):
    for name, value in values.items():
        version = versions[name.lower()]
        if version not in existing:
            run("docker", "secret", "create", version, "-", input=value)
            print(f"Creating secret: {name}")


def render(versions):
    for stack in sorted(ROOT.glob("platform/**/stack.yml")):
        original = stack.read_text()
        rendered = original
        for name, version in versions.items():
            rendered = re.sub(
                rf"^(  {re.escape(name)}:\n    external: true\n)(?:    name: [^\n]*\n)?",
                rf'\g<1>    name: "{version}"\n',
                rendered,
                flags=re.MULTILINE,
            )
        if rendered != original:
            stack.write_text(rendered)


def clean():
    names = {
        name.lower()
        for name in tomllib.loads((ROOT / "secretspec.toml").read_text())["scopes"][
            "swarm"
        ]["secrets"]
    }
    pattern = re.compile(rf"^(?:{'|'.join(map(re.escape, names))})_[a-f0-9]{{12}}$")
    referenced = set()
    for service in run("docker", "service", "ls", "-q").splitlines():
        spec = json.loads(run("docker", "service", "inspect", service))[0]
        secrets = spec["Spec"]["TaskTemplate"]["ContainerSpec"].get("Secrets", [])
        referenced.update(secret["SecretName"] for secret in secrets)
    for stack in ROOT.glob("platform/**/stack.yml"):
        referenced.update(
            re.findall(r'^    name: "([^"\n]+)"$', stack.read_text(), re.MULTILINE)
        )
    for name in run("docker", "secret", "ls", "--format", "{{.Name}}").splitlines():
        if pattern.fullmatch(name) and name not in referenced:
            run("docker", "secret", "rm", name)
            print(f"Removing secret: {name}")


def main():
    if sys.argv[1:] == ["clean"]:
        clean()
        return
    if sys.argv[1:]:
        raise SystemExit("Usage: python secrets.py [clean]")

    values = resolve(
        profile="production",
        scope="swarm",
        reason="reconcile Docker Swarm secrets",
    ).fields()
    encrypted = {}
    for line in SECRETS_FILE.read_text().splitlines():
        match = re.fullmatch(r"([A-Z][A-Z0-9_]*)=(ENC\[.+\])", line)
        if match:
            encrypted[match[1]] = match[2]
    missing = values.keys() - encrypted.keys()
    if missing:
        raise RuntimeError(
            f"Missing encrypted SOPS entries for: {', '.join(sorted(missing))}"
        )

    versions = {
        name.lower(): f"{name.lower()}_{hashlib.sha256(encrypted[name].encode()).hexdigest()[:12]}"
        for name in values
    }
    existing = set(run("docker", "secret", "ls", "--format", "{{.Name}}").splitlines())
    check(versions, existing)
    sync(versions, values, existing)
    render(versions)


if __name__ == "__main__":
    main()
