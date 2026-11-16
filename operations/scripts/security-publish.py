#!/usr/bin/env python3

import base64
import datetime
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path


def validate(snapshot):
    if (
        snapshot.get("schema_version") != 1
        or snapshot.get("complete") is not True
        or snapshot.get("mode") != "full"
    ):
        raise ValueError("Only complete inventory snapshots can be published")
    summary = snapshot["summary"][0]
    if not (
        summary["deployments"]
        == summary["expected_deployments"]
        == len(snapshot["deployments"])
        > 0
    ):
        raise ValueError("Incomplete snapshot coverage")
    if "database.json" not in snapshot["reports"] or any(
        deployment["report"] not in snapshot["reports"]
        for deployment in snapshot["deployments"]
    ):
        raise ValueError("Missing Trivy reports")
    for name, checksum in snapshot["reports"].items():
        if not re.fullmatch(
            r"database\.json|json/images/[a-f0-9]{64}(?:\.exceptions)?\.json", name
        ) or not re.fullmatch(r"[a-f0-9]{64}", checksum):
            raise ValueError("Invalid report path or checksum")
    if not re.fullmatch(r"[a-f0-9]{40}", summary["commit"]):
        raise ValueError("Invalid source commit")
    for field in ("run_id", "run_attempt"):
        if not re.fullmatch(r"[1-9][0-9]*", snapshot[field]):
            raise ValueError(f"Invalid {field}")
    timestamp = datetime.datetime.fromisoformat(summary["captured_at"])
    if timestamp.utcoffset() != datetime.timedelta(0):
        raise ValueError("Snapshot timestamp must be UTC")
    return f"snapshots/{timestamp:%Y%m%dT%H%M%S%fZ}-{snapshot['run_id']}-{snapshot['run_attempt']}"


def update(directory, snapshot, path, reports):
    for name, checksum in snapshot["reports"].items():
        if hashlib.sha256(reports[name]).hexdigest() != checksum:
            raise ValueError(f"Report changed after validation: {name}")
    index_path = directory / "index.json"
    index = (
        json.loads(index_path.read_text())
        if index_path.exists()
        else {
            "schema_version": 1,
            "latest": None,
            "snapshots": [],
            "options": [],
        }
    )
    if index["schema_version"] != 1:
        raise ValueError("Unsupported index schema")
    destination = directory / path / "manifest.json"
    encoded = json.dumps({**snapshot, "path": path}, separators=(",", ":")) + "\n"
    if destination.exists():
        if destination.read_text() != encoded:
            raise ValueError("Cannot overwrite an immutable snapshot")
        return False
    # A run attempt has exactly one immutable report, even if publication is retried.
    if any(
        (row["run_id"], row["run_attempt"])
        == (snapshot["run_id"], snapshot["run_attempt"])
        for row in index["snapshots"]
    ):
        raise ValueError("Run attempt already published with different content")
    summary = snapshot["summary"][0]
    entry = {
        **summary,
        "path": path,
        "run_id": snapshot["run_id"],
        "run_attempt": snapshot["run_attempt"],
    }
    advance = True
    if index["latest"]:
        previous = next(
            row for row in index["snapshots"] if row["path"] == index["latest"]
        )
        if previous["commit"] == summary["commit"]:
            advance = (int(entry["run_id"]), int(entry["run_attempt"])) > (
                int(previous["run_id"]),
                int(previous["run_attempt"]),
            )
        else:
            result = subprocess.run(
                [
                    "git",
                    "merge-base",
                    "--is-ancestor",
                    previous["commit"],
                    summary["commit"],
                ],
                cwd=directory,
                check=False,
            )
            if result.returncode not in (0, 1):
                raise ValueError("Cannot establish source commit ordering")
            advance = result.returncode == 0
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(encoded)
    for name in snapshot["reports"]:
        output = destination.parent / name
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_bytes(reports[name])
    index["snapshots"].append(entry)
    index["snapshots"].sort(
        key=lambda row: (int(row["run_id"]), int(row["run_attempt"])), reverse=True
    )
    if advance:
        index["latest"] = path
        (directory / "latest.json").write_text(encoded)
    index["options"] = [
        {"__text": "Latest complete inventory", "__value": "latest.json"}
    ] + [
        {
            "__text": f"{row['captured_at']} · {row['commit'][:8]} · {row['run_id']}/{row['run_attempt']}",
            "__value": f"{row['path']}/manifest.json",
        }
        for row in index["snapshots"]
    ]
    index_path.write_text(json.dumps(index, separators=(",", ":")) + "\n")
    return True


def publish():
    snapshot = json.loads(Path(".artifacts/security/snapshot.json").read_text())
    path = validate(snapshot)
    reports = {
        name: (Path(".artifacts/security") / name).read_bytes()
        for name in snapshot["reports"]
    }
    if (
        os.environ["GITHUB_REF"] != "refs/heads/main"
        or os.environ["GITHUB_EVENT_NAME"]
        not in ("push", "schedule", "workflow_dispatch")
        or snapshot["summary"][0]["commit"] != os.environ["GITHUB_SHA"]
        or snapshot["run_id"] != os.environ["GITHUB_RUN_ID"]
        or snapshot["run_attempt"] != os.environ["GITHUB_RUN_ATTEMPT"]
    ):
        raise ValueError("Snapshot does not belong to this trusted main-branch run")
    repository = os.environ["GITHUB_REPOSITORY"]
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository):
        raise ValueError("Invalid repository")
    credentials = base64.b64encode(
        f"x-access-token:{os.environ['GH_TOKEN']}".encode()
    ).decode()
    env = {
        **os.environ,
        "GIT_CONFIG_COUNT": "1",
        "GIT_CONFIG_KEY_0": "http.https://github.com/.extraheader",
        "GIT_CONFIG_VALUE_0": f"AUTHORIZATION: basic {credentials}",
        "GIT_TERMINAL_PROMPT": "0",
    }
    for _ in range(5):
        with tempfile.TemporaryDirectory(prefix="security-reports-") as temporary:
            directory = Path(temporary)

            def git(*args, directory=directory, **kwargs):
                return subprocess.run(
                    ["git", *args], cwd=directory, env=env, check=True, **kwargs
                )

            git("init", "--quiet")
            git("remote", "add", "origin", f"https://github.com/{repository}.git")
            git("fetch", "--quiet", "origin", "main")
            exists = git(
                "ls-remote",
                "--heads",
                "origin",
                "refs/heads/security-reports",
                capture_output=True,
                text=True,
            )
            if exists.stdout.strip():
                git("fetch", "--quiet", "origin", "refs/heads/security-reports")
                git("checkout", "--quiet", "-b", "security-reports", "FETCH_HEAD")
            else:
                git("checkout", "--quiet", "--orphan", "security-reports")
            if not update(directory, snapshot, path, reports):
                print(f"Already published: {path}")
                return
            git("add", "index.json", "latest.json", path)
            git(
                "-c",
                "user.name=github-actions[bot]",
                "-c",
                "user.email=41898282+github-actions[bot]@users.noreply.github.com",
                "commit",
                "--quiet",
                "-m",
                f"chore(security): publish inventory {snapshot['run_id']}/{snapshot['run_attempt']}",
            )
            try:
                git("push", "origin", "HEAD:refs/heads/security-reports")
                print(
                    f"Published {path} ({sum(len(content) for content in reports.values())} report bytes)"
                )
                return
            except subprocess.CalledProcessError:
                # Refetch and rebuild the atomic commit after a competing publication.
                continue
    raise ValueError("Could not publish after five attempts")


if __name__ == "__main__":
    try:
        publish()
    except (
        OSError,
        ValueError,
        KeyError,
        TypeError,
        IndexError,
        StopIteration,
        subprocess.CalledProcessError,
    ) as error:
        print(f"Security publication failed: {error}", file=sys.stderr)
        sys.exit(1)
