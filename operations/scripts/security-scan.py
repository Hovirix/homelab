#!/usr/bin/env python3

import hashlib
import json
import os
import re
import subprocess
import sys
import uuid
from pathlib import Path

DIR = Path(".artifacts/security")


def require(condition, message):
    if not condition:
        raise ValueError(message)


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2) + "\n")


def inventory(revision=None):
    if revision:
        paths = subprocess.check_output(
            ["git", "ls-tree", "-r", "--name-only", revision, "--", "platform"],
            text=True,
        ).splitlines()
    else:
        paths = [
            str(path)
            for path in Path("platform").rglob("stack.yml")
            if path.is_file() and not path.is_symlink()
        ]
    deployments = {}
    for stack in sorted(path for path in paths if path.endswith("/stack.yml")):
        content = (
            subprocess.check_output(["git", "show", f"{revision}:{stack}"], text=True)
            if revision
            else Path(stack).read_text()
        )
        data = json.loads(
            subprocess.check_output(
                ["yq", "-o=json", ".services", "-"], input=content, text=True
            )
        )
        require(isinstance(data, dict) and data, f"Missing service images: {stack}")
        for service, config in data.items():
            require(
                re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9_.-]*", service),
                f"Invalid service: {service}",
            )
            image = config.get("image")
            require(
                isinstance(image, str) and image.strip(),
                f"Missing image: {stack}/{service}",
            )
            target = f"{Path(stack).parent}/{service}"
            deployments[target] = {"target": target, "image": image, "stack": stack}
    return deployments


def scan():
    os.environ.setdefault("TRIVY_CONFIG", "security/trivy.yaml")
    DIR.mkdir(parents=True, exist_ok=True)
    for name in ("scan.complete", "manifest.json", "summary.md", "comment.md"):
        (DIR / name).unlink(missing_ok=True)
    for directory, pattern in (("json/images", "*.json"), ("sarif/images", "*.sarif")):
        path = DIR / directory
        path.mkdir(parents=True, exist_ok=True)
        for old in path.glob(pattern):
            old.unlink()

    mode = os.environ.get("SECURITY_MODE", "full")
    require(mode in ("pr", "full"), f"Unknown security mode: {mode}")
    base = ""
    reference = os.environ.get("SECURITY_BASE_REF")
    if mode == "pr":
        require(reference, "PR scans require SECURITY_BASE_REF")
        base = subprocess.check_output(
            ["git", "merge-base", "HEAD", reference], text=True
        ).strip()
    else:
        parent = subprocess.run(
            ["git", "rev-parse", "--verify", "HEAD^"],
            text=True,
            capture_output=True,
            check=False,
        )
        if parent.returncode == 0:
            base = parent.stdout.strip()
    current = inventory()
    previous = inventory(base) if base else {}
    require(current or previous, "No images found")
    config = os.environ["TRIVY_CONFIG"]
    inputs = [
        config,
        "operations/scripts/security-scan.py",
        "operations/scripts/security-report.py",
    ]
    selected, exceptions = [], []
    for target, deployment in current.items():
        ignore = Path(f"security/ignore/{target}.yaml")
        inputs.extend((deployment["stack"], str(ignore)))
        deployment["ignore"] = (
            str(ignore) if ignore.exists() or ignore.is_symlink() else "/dev/null"
        )
        if deployment["ignore"] != "/dev/null":
            exceptions.append(str(ignore))
        old = previous.get(target, {}).get("image")
        if mode == "pr" and old == deployment["image"]:
            changed = subprocess.run(
                ["git", "diff", "--quiet", base, "--", str(ignore), config], check=False
            )
            require(
                changed.returncode in (0, 1), "Cannot compare security configuration"
            )
            if changed.returncode == 0:
                continue
        deployment.update(
            id=hashlib.sha256(target.encode()).hexdigest(),
            base_image=old if mode == "pr" else None,
        )
        selected.append(deployment)
    images = {deployment["image"] for deployment in selected}
    images.update(
        deployment["base_image"] for deployment in selected if deployment["base_image"]
    )
    manifest = {
        "run_id": uuid.uuid4().hex,
        "commit": subprocess.check_output(
            ["git", "rev-parse", "HEAD"], text=True
        ).strip(),
        "base": base,
        "mode": mode,
        "stacks": sorted({deployment["stack"] for deployment in current.values()}),
        "inputs": {
            path: hashlib.sha256(Path(path).read_bytes()).hexdigest()
            if Path(path).exists()
            else None
            for path in sorted(set(inputs))
        },
        "deployments": selected,
        "removed": [
            deployment
            for target, deployment in previous.items()
            if target not in current
        ],
        "exceptions": exceptions,
        "images": sorted(images),
    }
    write_json(DIR / "manifest.json", manifest)
    empty = DIR / "empty.json"
    write_json(
        empty,
        {
            "SchemaVersion": 2,
            "ArtifactName": "removed",
            "ArtifactType": "container_image",
            "Results": [],
        },
    )
    for ignore in exceptions:
        subprocess.run(
            [
                "trivy",
                "convert",
                "--ignorefile",
                ignore,
                "--format",
                "json",
                "--output",
                "/dev/null",
                str(empty),
            ],
            check=True,
        )
    if images:
        subprocess.run(["trivy", "image", "--download-db-only"], check=True)
        subprocess.run(["trivy", "image", "--download-java-db-only"], check=True)
    database = subprocess.check_output(
        ["trivy", "--version", "--format", "json"], text=True
    )
    (DIR / "database.json").write_text(database)
    for image in sorted(images):
        name = hashlib.sha256(image.encode()).hexdigest()
        output = DIR / "json/images" / f"{name}.json"
        print(f"Scanning {image}", flush=True)
        subprocess.run(
            [
                "trivy",
                "image",
                "--scanners",
                "vuln",
                "--skip-db-update",
                "--skip-java-db-update",
                "--ignorefile",
                "/dev/null",
                "--exit-code",
                "0",
                "--list-all-pkgs",
                "--severity",
                "UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL",
                "--ignore-unfixed=false",
                "--format",
                "json",
                "--output",
                str(output),
                image,
            ],
            check=True,
        )
    (DIR / "database-end.json").write_text(
        subprocess.check_output(["trivy", "--version", "--format", "json"], text=True)
    )
    (DIR / "scan.complete").write_text(manifest["run_id"] + "\n")


if __name__ == "__main__":
    try:
        scan()
    except (
        OSError,
        ValueError,
        TypeError,
        KeyError,
        AttributeError,
        subprocess.CalledProcessError,
    ) as error:
        print(f"Image scanning failed: {error}", file=sys.stderr)
        sys.exit(1)
