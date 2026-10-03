#!/usr/bin/env python3

import re
import subprocess
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass


@dataclass
class Result:
    name: str
    passed: bool
    reason: str = ""


def run(*command):
    return subprocess.run(
        command,
        capture_output=True,
        text=True,
        check=False,
    )


def test_pve():
    result = run("task", "pve:plan")

    if result.returncode != 0:
        return [Result("pve", False, "plan failed")]

    output = result.stdout + result.stderr

    changed = [int(value) for value in re.findall(r"changed=(\d+)", output)]
    failed = [int(value) for value in re.findall(r"failed=(\d+)", output)]
    unreachable = [int(value) for value in re.findall(r"unreachable=(\d+)", output)]

    if not changed:
        return [Result("pve", False, "unable to read ansible recap")]

    if any(failed):
        return [Result("pve", False, "ansible failed")]

    if any(unreachable):
        return [Result("pve", False, "host unreachable")]

    if any(changed):
        return [Result("pve", False, "drift detected")]

    return [Result("pve", True)]


def test_infrastructure():
    stacks = [
        "adguardhome",
        "proxmox",
        "cloudflare",
        "authentik",
        "hetzner",
    ]

    results = []

    for stack in stacks:
        result = run("task", f"infra:{stack}:plan")

        if result.returncode != 0:
            results.append(Result(stack, False, "plan failed"))
            continue

        if "No changes." not in result.stdout:
            results.append(Result(stack, False, "drift detected"))
            continue

        results.append(Result(stack, True))

    return results


def test_swarm():
    result = run("task", "swarm:status")

    if result.returncode != 0:
        return [Result("swarm", False, "status failed")]

    return [Result("swarm", True)]


def test_services():
    services = {
        "grafana": "https://grafana.hovirix.dev/api/health",
        "authentik": "https://authentik.hovirix.dev/",
        "vaultwarden": "https://vaultwarden.hovirix.dev/alive",
        "paperless": "https://paperless.hovirix.dev/api/health/",
    }

    results = []

    for name, url in services.items():
        try:
            with urllib.request.urlopen(url, timeout=10) as response:
                if 200 <= response.status < 400:
                    results.append(Result(name, True))
                else:
                    results.append(Result(name, False, f"http {response.status}"))

        except urllib.error.HTTPError as error:
            results.append(Result(name, False, f"http {error.code}"))

        except urllib.error.URLError:
            results.append(Result(name, False, "unreachable"))

        except TimeoutError:
            results.append(Result(name, False, "timeout"))

    return results


def print_results(title, results):
    print(title)

    for result in results:
        status = "PASS" if result.passed else "FAIL"

        if result.reason:
            print(f"  {result.name}: {status} - {result.reason}")
        else:
            print(f"  {result.name}: {status}")

    print()


def main():
    tests = [
        ("Hypervisor", test_pve),
        ("Infrastructure", test_infrastructure),
        ("Platform", test_swarm),
        ("Services", test_services),
    ]

    results = []

    for title, function in tests:
        section_results = function()
        results.extend(section_results)
        print_results(title, section_results)

    passed = sum(result.passed for result in results)
    failed = len(results) - passed

    print("Summary")
    print(f"  Passed: {passed}")
    print(f"  Failed: {failed}")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
