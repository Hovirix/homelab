#!/usr/bin/env python3

import importlib.util
import io
import json
import os
import shlex
import subprocess
import sys
import tempfile
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location(
    "restore", Path(__file__).with_name("restore.py")
)
restore = importlib.util.module_from_spec(spec)
spec.loader.exec_module(restore)


def main():
    for answers, multiple, expected in (
        (["invalid", "99", "9" * 5000, "2"], False, "paperless"),
        (["1 2", "1"], False, "postgres"),
        (["0", "1 2 1"], True, ["postgres", "paperless"]),
    ):
        with patch("builtins.input", side_effect=answers):
            assert (
                restore.choose("", ["postgres", "paperless"], multiple=multiple)
                == expected
            )
    with patch("builtins.input", return_value=""):
        try:
            restore.choose("", ["postgres"], cancel=True)
        except SystemExit as error:
            assert error.code == 0
        else:
            raise AssertionError("Blank menu selection did not cancel")

    for mount in (
        "/",
        "/var/mnt",
        "/var/mnt/swarm/postgres/",
        "/var/mnt/swarm/postgres/pgdata",
    ):
        try:
            restore.assert_mounts_unused(mount, ["postgres"])
        except RuntimeError:
            pass
        else:
            raise AssertionError(f"Writable mount accepted: {mount}")
    restore.assert_mounts_unused("\n/var/mnt/swarm/postgres-other", ["postgres"])

    def docker(command):
        args = shlex.split(command)[3:]
        if args[0] == "info":
            return "active|true\n"
        if args[:2] == ["service", "ls"]:
            return "service-1\n"
        if args[0] == "ps":
            return "container-1\n"
        if "inspect" in args:
            return mounts["service" if args[0] == "service" else "container"]
        raise AssertionError(command)

    mounts = {"service": "", "container": ""}
    with (
        patch.dict(os.environ, MANAGER_HOSTS="node-1 node-2"),
        patch.object(restore, "run", side_effect=docker) as run,
    ):
        assert restore.assert_unused(["postgres"]) == "node-1"
        for host in ("node-1", "node-2"):
            assert any(
                call.args[0] == f"docker --host {host} ps -q"
                for call in run.call_args_list
            )
        for source in mounts:
            mounts[source] = "/var/mnt/swarm/postgres"
            try:
                restore.assert_unused(["postgres"])
            except RuntimeError:
                pass
            else:
                raise AssertionError(f"{source} writer accepted")
            mounts[source] = ""
        for datasets in ([], ["../postgres"], ["postgres;id"]):
            run.reset_mock()
            try:
                restore.assert_unused(datasets)
            except RuntimeError:
                pass
            else:
                raise AssertionError(datasets)
            run.assert_not_called()

    with patch.object(
        restore,
        "run",
        side_effect=[subprocess.CalledProcessError(1, "docker"), "active|true\n"],
    ):
        assert restore.manager_host(["node-1", "node-2"]) == "node-2"

    def listing(command):
        if command.startswith("zfs list -H -o name"):
            return "rpool/swarm\nrpool/swarm/postgres\nrpool/swarm/paperless\n"
        if command.startswith("zfs list -H -p"):
            return "rpool/swarm/postgres@test\t1794031200\n"
        if "repo-list --json" in command:
            return json.dumps(
                [
                    {
                        "archives": [
                            {"name": "pve-test", "time": "2026-11-07T02:10:00"},
                            {"name": "pve-old", "time": "2026-11-06T02:03:00+00:00"},
                        ]
                    }
                ]
            )
        if " list --archive " in command:
            return (
                "rpool/swarm/postgres/pgdata/file\nrpool/swarm/paperless/media/file\n"
            )
        raise AssertionError(command)

    for answers, action, arguments, datasets in (
        (
            ["1", "2", "1"],
            "local",
            ["postgres", "rpool/swarm/postgres@test", "2026-11-07 06:00 UTC"],
            ["postgres"],
        ),
        (
            ["2", "1", "2 1"],
            "offsite",
            ["pve-test", "2026-11-07 02:10 UTC", "postgres", "paperless"],
            ["postgres", "paperless"],
        ),
        (
            ["3", "1", "1"],
            "extract",
            ["pve-test", "2026-11-07 02:10 UTC", "paperless"],
            [],
        ),
    ):
        with (
            patch.dict(os.environ, PVE="test-pve"),
            patch.object(sys.stdin, "isatty", return_value=True),
            patch("builtins.input", side_effect=answers) as selection,
            patch.object(restore, "remote", side_effect=listing) as remote,
            patch.object(restore, "assert_unused") as unused,
            patch.object(restore, "run") as run,
            patch.object(restore, "resolve") as resolve,
            redirect_stdout(io.StringIO()) as output,
        ):
            restore.main()
            run.assert_called_once()
            command = shlex.split(run.call_args.args[0])[-1]
            assert shlex.split(command) == [
                "/usr/local/sbin/restore",
                action,
                *arguments,
            ], command
            assert run.call_args.kwargs == {"capture": False}
            assert (
                selection.call_args_list[0].args[0] == "Choose [1–4, Enter to cancel]: "
            )
            assert (
                "1. Local snapshot\n2. Off-site backup\n3. Extract backup only\n4. PostgreSQL dump — ALL databases"
                in output.getvalue()
            )
            if datasets:
                unused.assert_called_once_with(datasets)
            else:
                unused.assert_not_called()
                assert "Checking writers" not in output.getvalue()
            resolve.assert_not_called()

    with (
        patch.dict(os.environ),
        patch.object(sys.stdin, "isatty", return_value=True),
        patch("builtins.input", return_value="4"),
        patch.object(
            restore, "assert_unused", return_value="ssh://test-manager"
        ) as unused,
        patch.object(restore, "restore_postgres") as postgres,
    ):
        restore.main()
        unused.assert_called_once_with(["postgres"])
        assert os.environ["DOCKER_HOST"] == "ssh://test-manager"
        postgres.assert_called_once_with()

    for answers in (["1", "1"], ["2", "1", "1"], ["4"]):
        with (
            patch.object(sys.stdin, "isatty", return_value=True),
            patch("builtins.input", side_effect=answers),
            patch.object(
                restore,
                "assert_unused",
                side_effect=RuntimeError("Writer still active"),
            ),
            patch.object(restore, "run") as run,
            patch.object(restore, "remote", side_effect=listing) as remote,
            patch.object(restore, "resolve") as resolve,
        ):
            try:
                restore.main()
            except RuntimeError:
                pass
            else:
                raise AssertionError("Recovery continued after a failed preflight")
            run.assert_not_called()
            assert all("mktemp" not in call.args[0] for call in remote.call_args_list)
            resolve.assert_not_called()

    choices = restore.dump_choices(
        "100\tdigest-old\t/old.sql.gz\n200\tdigest-new\t/new.sql.gz\n100\tdigest-new\t/copy.sql.gz"
    )
    assert list(choices.values()) == [
        ("/new.sql.gz", "digest-new"),
        ("/old.sql.gz", "digest-old"),
    ]
    choices = restore.dated_choices(
        [
            (restore.datetime.fromisoformat("2026-11-07T02:10:00"), "naive"),
            (restore.datetime.fromisoformat("2026-11-07T03:10:00+01:00"), "offset"),
            (restore.datetime.fromisoformat("2026-11-06T02:03:00+00:00"), "older"),
        ]
    )
    assert len(choices) == 3 and set(choices.values()) == {"naive", "offset", "older"}
    assert next(iter(choices)) == "2026-11-07 02:10"
    assert list(choices.values())[-1] == "older"

    with (
        patch.object(restore, "remote", return_value="18"),
        patch.object(restore, "run", return_value="postgres (PostgreSQL) 18.6"),
        redirect_stdout(io.StringIO()) as output,
    ):
        assert (
            restore.validate_dump("/stage", "/dump.sql.gz", "digest", "postgres:18")
            == "18"
        )
        assert output.getvalue().strip().splitlines() == [
            "Checksum... OK",
            "Dump format... OK",
            "PostgreSQL version... OK",
            "Free space... OK",
        ]

    with (
        patch.dict(os.environ),
        patch.object(sys.stdin, "isatty", return_value=True),
        patch("builtins.input", return_value="4"),
        patch.object(restore, "assert_unused", return_value="test-manager"),
        patch.object(restore, "resolve") as resolve,
        patch.object(restore, "run", return_value="postgres:18"),
        patch.object(
            restore, "remote", side_effect=[restore.ROOT + "/restore-Ab12Cd34", ""]
        ),
        patch.object(restore, "verify_storage"),
        patch.object(restore, "backup_current"),
        patch.object(
            restore,
            "select_backup",
            return_value=("/dump", "digest", "2026-11-06 00:00 UTC"),
        ),
        patch.object(restore, "validate_dump"),
        patch.object(restore, "preserve_original"),
        patch.object(restore, "restore_cluster"),
        patch.object(restore, "verify_and_reconcile"),
        redirect_stdout(io.StringIO()) as output,
    ):
        resolve.return_value.fields.return_value = {
            f"POSTGRES_{role.upper()}_PASSWORD": "test-password"
            for role in restore.PASSWORDS
        }
        restore.main()
        text = output.getvalue()
        for message in (
            "[1/5] Check",
            "[2/5] Back up current data",
            "[3/5] Choose dump",
            "[4/5] Restore",
            "[5/5] Restore complete",
            "Scope: ALL databases",
            "Application checks: PENDING",
            "Next: task deploy, then verify applications.",
        ):
            assert message in text, text

    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        standalone = root / "restore.py"
        standalone.write_text(Path(restore.__file__).read_text())
        result = subprocess.run(
            [sys.executable, str(standalone)],
            cwd=root,
            input="",
            text=True,
            capture_output=True,
            check=False,
            timeout=10,
        )
        assert result.returncode == 1, result
        assert result.stderr.strip() == "ERROR: Interactive terminal required", (
            result.stderr
        )

        worker = root / "restore"
        worker.write_text(
            Path("infrastructure/ansible/roles/backup/templates/restore.sh.j2")
            .read_text()
            .replace("{% raw %}", "")
            .replace("{% endraw %}", "")
        )
        for arguments in (
            [],
            ["../postgres", "snapshot", "time"],
            ["postgres", "rpool/swarm/paperless@test", "time"],
        ):
            result = subprocess.run(
                ["bash", str(worker), "local", *arguments],
                capture_output=True,
                check=False,
            )
            assert result.returncode != 0, arguments
        environment = root / "shell-env"
        environment.write_text("""zfs() {
  case "$1" in
    get) if [ "$5" = mounted ]; then echo yes; else echo "/$6"; fi ;;
    list) echo rpool/swarm/postgres@test ;;
    rollback) echo rollback >> "$CALLS" ;;
    *) return 1 ;;
  esac
}
realpath() { printf '%s\\n' "$2"; }
mktemp() {
  if [ "${1:-}" = -d ]; then
    command mktemp -d "$TEST_ROOT/stage-XXXXXX"
  else
    command mktemp "$TEST_ROOT/list-XXXXXX"
  fi
}
borgmatic() {
  case " $* " in
    *' list '*) printf 'rpool/swarm/postgres/pgdata/file\\nrpool/swarm/paperless/media/file\\n' ;;
    *' check '*) return "${BACKUP_ERROR:-0}" ;;
    *' extract '*)
      while [ "$#" -gt 0 ]; do
        case "$1" in
          --destination) destination="$2"; shift ;;
          --path) dataset="${2##*/}"; shift ;;
        esac
        shift
      done
      mkdir -p "$destination/$dataset"
      printf data > "$destination/$dataset/file"
      echo extract >> "$CALLS"
      ;;
    *) return 1 ;;
  esac
}
rsync() {
  case " $* " in *' --delete '*) echo rsync >> "$CALLS" ;; *) return 1 ;; esac
}
""")
        log = root / "calls"
        for confirmation in ("CANCEL", "ROLLBACK"):
            log.write_text("")
            result = subprocess.run(
                [
                    "bash",
                    str(worker),
                    "local",
                    "postgres",
                    "rpool/swarm/postgres@test",
                    "2026-11-07 06:00 UTC",
                ],
                env=dict(os.environ, BASH_ENV=str(environment), CALLS=str(log)),
                input=f"{confirmation}\n",
                text=True,
                capture_output=True,
                check=False,
                timeout=10,
            )
            assert (result.returncode == 0) == (confirmation == "ROLLBACK"), (
                result.stderr
            )
            assert log.read_text() == (
                "rollback\n" if confirmation == "ROLLBACK" else ""
            )
            assert "Deletes newer data AND snapshots." in result.stdout
            assert "Snapshot: 2026-11-07 06:00 UTC" in result.stdout

        for mode, datasets, answer, backup_error, expected in (
            (
                "offsite",
                ["postgres", "paperless"],
                "CANCEL",
                "0",
                ["extract", "extract"],
            ),
            (
                "offsite",
                ["postgres", "paperless"],
                "RESTORE",
                "0",
                ["extract", "extract", "rsync", "rsync"],
            ),
            ("extract", ["paperless"], "", "0", ["extract"]),
            ("offsite", ["postgres"], "RESTORE", "1", []),
        ):
            log.write_text("")
            result = subprocess.run(
                [
                    "bash",
                    str(worker),
                    mode,
                    "pve-test",
                    "2026-11-07 02:10 UTC",
                    *datasets,
                ],
                env=dict(
                    os.environ,
                    BASH_ENV=str(environment),
                    CALLS=str(log),
                    TEST_ROOT=str(root),
                    BACKUP_ERROR=backup_error,
                ),
                input=answer + "\n",
                text=True,
                capture_output=True,
                check=False,
                timeout=10,
            )
            assert log.read_text().splitlines() == expected, (
                result.stderr,
                log.read_text(),
            )
            assert (result.returncode == 0) == (
                backup_error == "0" and (mode == "extract" or answer == "RESTORE")
            ), result.stderr
            if mode == "extract":
                assert (
                    "Extraction complete." in result.stdout
                    and "Live data unchanged." in result.stdout
                )
            elif backup_error == "0":
                assert "Overwrites live files." in result.stdout
                assert "failure may leave partial data." in result.stdout
                assert ("Restore complete." in result.stdout) == (answer == "RESTORE")
    print("Interactive restore checks passed")


if __name__ == "__main__":
    main()
