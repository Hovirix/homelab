#!/usr/bin/env python3

import gzip
import os
import shlex
import subprocess
import tempfile
import time
from pathlib import Path


def main():
    script = "infrastructure/ansible/roles/backup/templates/check-postgres-dump.sh.j2"
    hooks = [
        line.strip()[2:]
        for line in Path(
            "infrastructure/ansible/roles/backup/templates/borgmatic.yaml.j2"
        )
        .read_text()
        .splitlines()
        if line.strip().startswith("- /usr/local/sbin/check-postgres-dump ")
    ]
    assert len(hooks) == 2
    assert all("||" not in hook for hook in hooks)
    with tempfile.TemporaryDirectory() as directory:
        dump = Path(directory) / "postgres.sql.gz"
        latest = Path(directory) / "postgres-latest.sql.gz"
        latest.symlink_to(dump.name)
        for contents, age, expected in (
            (None, 0, 1),
            (b"", 0, 1),
            (b"invalid gzip", 0, 1),
            (gzip.compress(b"SELECT 1;"), 21601, 1),
            (gzip.compress(b"SELECT 1;"), 86400, 1),
            (gzip.compress(b"SELECT 1;"), -3600, 1),
            (gzip.compress(b"SELECT 1;"), 3600, 0),
        ):
            if contents is not None:
                dump.write_bytes(contents)
                timestamp = time.time() - age
                os.utime(dump, (timestamp, timestamp))
            result = subprocess.run(
                ["bash", script, str(latest)],
                capture_output=True,
                text=True,
                check=False,
            )
            assert bool(result.returncode) == bool(expected), result
            assert ("ERROR: PostgreSQL dump " in result.stderr) == bool(expected), (
                result
            )
            assert result.stdout == "", result
            for hook in hooks:
                command = hook.replace(
                    "/usr/local/sbin/check-postgres-dump", "bash " + shlex.quote(script)
                ).replace(
                    "/rpool/swarm/postgres/backups/daily/postgres-latest.sql.gz",
                    shlex.quote(str(latest)),
                )
                result = subprocess.run(
                    ["bash", "-c", command], capture_output=True, text=True, check=False
                )
                assert bool(result.returncode) == bool(expected), result
    print("PostgreSQL dump validation checks passed")


if __name__ == "__main__":
    main()
