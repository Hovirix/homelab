#!/usr/bin/env python3

import datetime
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import quote

DIR = Path(".artifacts/security")
SEVERITIES = ("CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN")
POLICY = "Block introduced, unexcepted, fixable HIGH/CRITICAL findings; inherited findings remain backlog."


def require(condition, message):
    if not condition:
        raise ValueError(message)


def digest(text):
    return hashlib.sha256(text.encode()).hexdigest()


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2) + "\n")


def fingerprints(paths):
    return {
        path: hashlib.sha256(Path(path).read_bytes()).hexdigest()
        if Path(path).exists()
        else None
        for path in sorted(set(paths))
    }


def validate_exception(path):
    data = json.loads(subprocess.check_output(["yq", "-o=json", str(path)], text=True))
    require(
        isinstance(data, dict) and set(data) == {"vulnerabilities"},
        f"Invalid exception file: {path}",
    )
    require(
        isinstance(data["vulnerabilities"], list),
        f"Expected vulnerability list: {path}",
    )
    for entry in data["vulnerabilities"]:
        allowed = {"id", "owner", "statement", "expired_at", "paths", "purls"}
        require(
            isinstance(entry, dict) and not set(entry) - allowed,
            f"Invalid exception: {path}",
        )
        for field in ("id", "owner", "statement"):
            require(
                isinstance(entry.get(field), str) and entry[field].strip(),
                f"Missing {field}: {path}",
            )
        expiry = datetime.date.fromisoformat(entry.get("expired_at", ""))
        require(
            expiry.isoformat() == entry["expired_at"], f"Invalid exception date: {path}"
        )
        require(
            expiry > datetime.datetime.now(datetime.UTC).date(),
            f"Expired exception: {path}",
        )
        for field in ("paths", "purls"):
            values = entry.get(field, [])
            require(isinstance(values, list), f"Invalid {field}: {path}")
            require(
                all(isinstance(value, str) and value.strip() for value in values),
                f"Invalid {field}: {path}",
            )


def package_version(package):
    version = package.get("Version", "")
    if package.get("Release"):
        version += f"-{package['Release']}"
    if package.get("Epoch"):
        version = f"{package['Epoch']}:{version}"
    return version


def load_report(path, image):
    data = json.loads(path.read_text())
    require(
        data.get("SchemaVersion") == 2
        and data.get("ArtifactType") == "container_image",
        f"Invalid scan: {path}",
    )
    require(data.get("ArtifactName") == image, f"Wrong scanned image: {path}")
    require(
        re.fullmatch(
            r"sha256:[a-f0-9]{64}", data.get("Metadata", {}).get("ImageID", "")
        ),
        f"Missing image ID: {path}",
    )
    require(isinstance(data.get("Results"), list), f"Missing scan results: {path}")
    for result in data["Results"]:
        require(
            result.get("Class") in ("os-pkgs", "lang-pkgs")
            and result.get("Target")
            and result.get("Type"),
            f"Invalid package target: {path}",
        )
        require(
            isinstance(result.get("Packages"), list),
            f"Missing package inventory: {path}",
        )
        packages = {
            (package["Name"], package_version(package))
            for package in result["Packages"]
        }
        package_ids = {
            (package["ID"], package["Name"])
            for package in result["Packages"]
            if package.get("ID")
        }
        for vuln in result.get("Vulnerabilities", []):
            require(
                vuln.get("VulnerabilityID") and vuln.get("Severity") in SEVERITIES,
                f"Invalid finding: {path}",
            )
            require(
                vuln.get("PkgName") and vuln.get("InstalledVersion"),
                f"Incomplete finding: {path}",
            )
            require(
                (vuln["PkgID"], vuln["PkgName"]) in package_ids
                if vuln.get("PkgID")
                else (vuln["PkgName"], vuln["InstalledVersion"]) in packages,
                f"Finding missing from package inventory: {path}",
            )
    return data


def target_key(result):
    return f"os/{result['Type']}" if result["Class"] == "os-pkgs" else result["Target"]


def findings(data):
    found = {}
    for result in data.get("Results", []):
        for vuln in result.get("Vulnerabilities", []):
            key = (vuln["VulnerabilityID"], vuln["PkgName"], target_key(result))
            found.setdefault(key, []).append(vuln)
    return found


def compare(old, new):
    before, after = findings(old), findings(new)
    groups = {
        "Introduced": after.keys() - before.keys(),
        "Inherited": after.keys() & before.keys(),
        "Patched": set(),
        "Removed": set(),
        "No longer detected": set(),
    }
    packages = {}
    for result in new["Results"]:
        for package in result["Packages"]:
            packages.setdefault((package["Name"], target_key(result)), set()).add(
                package_version(package)
            )
    for key in before.keys() - after.keys():
        versions = packages.get(key[1:])
        fixes = {
            version.strip()
            for vuln in before[key]
            for version in vuln.get("FixedVersion", "").split(",")
            if version.strip()
        }
        affected = {vuln["InstalledVersion"] for vuln in before[key]}
        # shortcut: exact fixed versions only; broader classification needs upstream range evaluation.
        if versions is None:
            groups["Removed"].add(key)
        elif versions <= fixes and not versions & affected:
            groups["Patched"].add(key)
        else:
            groups["No longer detected"].add(key)
    require(
        sum(len(groups[name]) for name in ("Patched", "Removed", "No longer detected"))
        == len(before.keys() - after.keys()),
        "Incomplete disappearance classification",
    )
    return before, after, groups


def severity(vulnerabilities):
    return min((vuln["Severity"] for vuln in vulnerabilities), key=SEVERITIES.index)


def fixable(vuln):
    return bool(vuln.get("FixedVersion")) and vuln["Severity"] in ("HIGH", "CRITICAL")


def fixable_count(found):
    return sum(any(fixable(vuln) for vuln in vulns) for vulns in found.values())


def gate_candidates(deployment, source):
    path = DIR / "json/images" / f"{deployment['id']}.gate.json"
    path.unlink(missing_ok=True)
    subprocess.run(
        [
            "trivy",
            "convert",
            "--ignorefile",
            deployment["ignore"],
            "--severity",
            "HIGH,CRITICAL",
            "--format",
            "json",
            "--output",
            str(path),
            str(source),
        ],
        check=True,
    )
    data = load_report(path, deployment["image"])
    for result in data["Results"]:
        result["Vulnerabilities"] = [
            vuln for vuln in result.get("Vulnerabilities", []) if fixable(vuln)
        ]
    write_json(path, data)
    return data


def table(columns):
    lines = [
        "| Severity | " + " | ".join(columns) + " |",
        "|---|" + "---:|" * len(columns),
    ]
    for level in SEVERITIES:
        counts = [
            sum(severity(vulns) == level for vulns in values.values())
            for values in columns.values()
        ]
        lines.append(f"| {level} | " + " | ".join(map(str, counts)) + " |")
    return "\n".join(lines) + "\n\n"


def sarif(target, source):
    path = DIR / "sarif/images" / f"{digest(target)}.sarif"
    path.unlink(missing_ok=True)
    subprocess.run(
        [
            "trivy",
            "convert",
            "--ignorefile",
            "/dev/null",
            "--format",
            "sarif",
            "--output",
            str(path),
            str(source),
        ],
        check=True,
    )
    data = json.loads(path.read_text())
    run = data["runs"][0]
    run["automationDetails"] = {"id": f"images/{target}/"}
    for result in run.get("results", []):
        package = result["message"]["text"].splitlines()[0].removeprefix("Package: ")
        for location in result.get("locations", []):
            physical = location["physicalLocation"]
            original = physical["artifactLocation"]["uri"]
            physical["artifactLocation"]["uri"] = (
                f"images/{target}/{quote(original, safe='')}/{quote(package, safe='')}"
            )
            physical["region"] = {"startLine": 1, "startColumn": 1}
    write_json(path, data)


def report():
    manifest = json.loads((DIR / "manifest.json").read_text())
    require(
        (DIR / "scan.complete").read_text().strip() == manifest["run_id"],
        "Image scanning did not complete",
    )
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    require(
        commit == manifest["commit"]
        and fingerprints(manifest["inputs"]) == manifest["inputs"],
        "Scan inputs changed; rescan before reporting",
    )
    stacks = sorted(
        str(path)
        for path in Path("platform").rglob("stack.yml")
        if path.is_file() and not path.is_symlink()
    )
    require(
        stacks == manifest["stacks"], "Stack inventory changed; rescan before reporting"
    )
    database = json.loads((DIR / "database.json").read_text())
    require(
        database == json.loads((DIR / "database-end.json").read_text()),
        "Scanner databases changed during scanning",
    )
    for path in manifest["exceptions"]:
        validate_exception(Path(path))
    summary, comment, failed, glance = [], [], False, {}
    for deployment in manifest["deployments"]:
        target, image = deployment["target"], deployment["image"]
        source = DIR / "json/images" / f"{digest(image)}.json"
        current = load_report(source, image)
        old_image = deployment["base_image"]
        old = (
            load_report(DIR / "json/images" / f"{digest(old_image)}.json", old_image)
            if old_image
            else {"Results": []}
        )
        before, after, groups = compare(old, current)
        counts = [
            sum(severity(vulns) == level for vulns in after.values())
            for level in ("CRITICAL", "HIGH")
        ]
        glance[image] = (*counts, fixable_count(after))
        gate = gate_candidates(deployment, source)
        require(
            gate["Metadata"]["ImageID"] == current["Metadata"]["ImageID"],
            f"Gate scanned a different image: {target}",
        )
        eligible = findings(gate)
        require(
            eligible.keys() <= after.keys(),
            f"Gate results disagree with raw scan: {target}",
        )
        blockers = eligible.keys() - before.keys()
        full = manifest["mode"] == "full"
        failed |= bool(blockers) and not full
        columns = {"Current": after} if full else {"Current": before, "Proposed": after}
        if not full:
            for name, keys in groups.items():
                values = after if name in ("Introduced", "Inherited") else before
                columns[name] = {key: values[key] for key in keys}
        text = f"## `{target}`\n\nProposed: `{image}`\n\n"
        if not full:
            text += f"Current: `{old_image or 'new service'}`\n\n"
        text += table(columns)
        if not full:
            text += f"Fixable HIGH/CRITICAL (before exceptions): **{fixable_count(before)} → {fixable_count(after)}**.\n\n"
        if full:
            text += f"**Inventory report: {len(eligible)} unexcepted, fixable HIGH/CRITICAL findings; no PR gate applied.**\n\n"
        elif blockers:
            text += f"**Gate: failed — {len(blockers)} introduced, unexcepted, fixable HIGH/CRITICAL findings.**\n\n"
        else:
            text += "**Gate: passed — no introduced blockers. Inherited findings remain remediation backlog.**\n\n"
        comment.append(text)
        if not full:
            text += "Patched requires an exact upstream fixed version; removal and unconfirmed disappearance are separate outcomes.\n\n"
            for name, keys in {**groups, "Blocking": blockers}.items():
                if keys and name != "Inherited":
                    text += f"<details><summary>{name} findings</summary>\n\n```text\n"
                    text += (
                        "\n".join("\t".join(key) for key in sorted(keys))
                        + "\n```\n\n</details>\n\n"
                    )
        summary.append(text)
        sarif(target, source)
    for deployment in manifest["removed"]:
        text = f"## Removed deployment: `{deployment['target']}`\n\nImage removed: `{deployment['image']}`. Findings are retired, not classified as patched.\n\n"
        summary.append(text)
        comment.append(text)
        sarif(deployment["target"], DIR / "empty.json")
    if not summary:
        summary.append("No changed images or image exceptions.\n")
        comment.extend(summary)
    if glance:
        width = max(len(image.split("@", 1)[0]) for image in glance)
        print(f"{'IMAGE':<{width}}  CRITICAL  HIGH  FIXABLE H/C")
        for image, (critical, high, fixable_total) in sorted(glance.items()):
            name = image.split("@", 1)[0]
            print(f"{name:<{width}}  {critical:>8}  {high:>4}  {fixable_total:>11}")
        print(
            f"\nInventory: {len(glance)} images, {sum(row[2] for row in glance.values())} fixable HIGH/CRITICAL findings."
        )
    return failed, "".join(summary), "".join(comment), manifest["mode"] == "full"


def publish_files(failed, summary, comment, inventory=False):
    status = "failed" if failed else "scan completed" if inventory else "passed"
    header = f"# Image security: {status}\n\n{POLICY}\n\n"
    summary = header + summary
    (DIR / "summary.md").write_text(summary)
    encoded = (header + comment).encode()
    comment = encoded[:50000].decode(errors="ignore")
    if len(encoded) > 50000:
        comment += "\n\n_Report shortened; see the full report._\n"
    url = os.environ.get("REPORT_URL")
    if url:
        comment += f"\n\n[Full report and logs]({url})\n"
    (DIR / "comment.md").write_text(comment)
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as output:
            output.write(summary)
    print(f"Image security: {status}. Report: {DIR / 'summary.md'}")


def main():
    DIR.mkdir(parents=True, exist_ok=True)
    os.environ.setdefault("TRIVY_CONFIG", "security/trivy.yaml")
    inventory = False
    try:
        require(not sys.argv[1:], "Usage: security-report.py")
        failed, summary, comment, inventory = report()
    except (
        OSError,
        ValueError,
        TypeError,
        KeyError,
        AttributeError,
        IndexError,
        subprocess.CalledProcessError,
    ) as error:
        failed = True
        print(f"Image security error: {error}", file=sys.stderr)
        summary = comment = (
            f"**Scanner or validation error:** {error}\n\nSee the run logs. This is not a clean scan.\n"
        )
    publish_files(failed, summary, comment, inventory)
    return int(failed)


if __name__ == "__main__":
    sys.exit(main())
