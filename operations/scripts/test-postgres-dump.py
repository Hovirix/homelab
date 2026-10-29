#!/usr/bin/env python3

import gzip
import os
import subprocess
import tempfile
import time
from pathlib import Path


def main():
    script = "infrastructure/ansible/roles/backup/templates/check-postgres-dump.sh.j2"
    with tempfile.TemporaryDirectory() as directory:
        dump = Path(directory) / "postgres.sql.gz"
        latest = Path(directory) / "postgres-latest.sql.gz"
        latest.symlink_to(dump.name)
        for contents, age, expected in (
            (None, 0, 1),
            (b"", 0, 1),
            (b"invalid gzip", 0, 1),
            (gzip.compress(b"SELECT 1;"), 108001, 1),
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
                check=False,
            )
            assert bool(result.returncode) == bool(expected), result
            result = subprocess.run(
                [
                    "bash",
                    "-c",
                    'bash "$1" "$2" || echo postgres_dump_validation_failed',
                    "--",
                    script,
                    str(latest),
                ],
                capture_output=True,
                text=True,
                check=False,
            )
            assert result.returncode == 0, result
            assert ("postgres_dump_validation_failed" in result.stdout) == bool(
                expected
            )
    print("PostgreSQL dump validation checks passed")


if __name__ == "__main__":
    main()
