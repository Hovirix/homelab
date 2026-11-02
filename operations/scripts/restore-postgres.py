#!/usr/bin/env python3
"""Restore a cluster dump into fresh production storage; never restart applications."""

import json
import os
import re
import shlex
import subprocess
import sys
import time
from datetime import datetime, timezone

ROOT = "/rpool/swarm/postgres"
VMROOT = "/var/mnt/swarm/postgres"
DATABASES = {"postgres", "authentik", "grafana", "paperless", "vaultwarden"}
PASSWORDS = ("superuser", "authentik", "grafana", "paperless", "vaultwarden")


def run(command, *, input=None):
    """Run a native CLI without a shell and stop on its first error."""
    return subprocess.run(
        shlex.split(command), input=input, text=True, capture_output=True, check=True
    ).stdout


def remote(script):
    """Run fixed host-side commands with private file permissions."""
    try:
        return run(
            f"ssh -T -o BatchMode=yes -o ConnectTimeout=10 {shlex.quote(os.environ['PVE'])} 'bash -seuo pipefail'",
            input="umask 077\n"
            + 'trap \'printf "Remote restore command failed at line %s (exit %s)\\n" "$LINENO" "$?" >&2\' ERR\n'
            + script,
        )
    except subprocess.CalledProcessError as error:
        detail = (error.stderr or "").strip() or f"exit status {error.returncode}"
        raise RuntimeError(f"Restore host failed: {detail}") from error


def choose(prompt, options):
    """Return an explicit numbered selection, never a fallback backup."""
    if not options:
        raise RuntimeError("No recovery points found")
    if prompt:
        print(prompt)
    for index, option in enumerate(options, 1):
        print(f"{index}. {option}")
    while True:
        answer = input("Selection: ")
        if answer.isdecimal() and 1 <= int(answer) <= len(options):
            return options[int(answer) - 1]


def confirm(word):
    """Require the exact confirmation word before changing production storage."""
    if input(f"Type {word} to continue: ") != word:
        raise RuntimeError("Cancelled")
    print()


def dump_choices(listing):
    """Sort newest first and remove duplicate retention copies.

    Parameters
    ----------
    listing : str
        Tab-separated timestamp, SHA-256 digest and dump path.

    Returns
    -------
    dict
        Display labels mapped to dump paths and hashes.
    """
    choices, seen = {}, set()
    for stamp, digest, path in sorted(
        (line.split("\t") for line in listing.splitlines()),
        key=lambda row: (-int(row[0]), row[2]),
    ):
        if digest not in seen:
            seen.add(digest)
            date = datetime.fromtimestamp(int(stamp), timezone.utc).strftime(
                "%Y-%m-%d %H:%M UTC"
            )
            label = date if date not in choices else f"{date} ({path})"
            choices[label] = (path, digest)
    return choices


def select_backup(stage):
    """Select a local dump or extract Borg dumps without replacing live files."""
    source = ROOT + "/backups"
    selected_source = choose("Backup source:", ["Local backups", "Borg archives"])
    print(f"\nSource: {selected_source}\n", flush=True)
    if selected_source == "Borg archives":
        listing = remote("borgmatic --no-color repo-list --short\n").splitlines()
        archive = shlex.quote(
            choose(
                "Archive:",
                sorted(
                    (a for a in listing if a and "Listing archives" not in a),
                    reverse=True,
                ),
            )
        )
        remote(
            f"borgmatic check --only data --match-archives {archive} --force\nborgmatic extract --archive {archive} --path rpool/swarm/postgres/backups --destination {stage}\n"
        )
        source = stage + "/rpool/swarm/postgres/backups"
    listing = remote(f"""test -d {source}
find {source} -type f -name '*.sql.gz' -print0 | while IFS= read -r -d '' file; do
  stamp=$(stat -c %Y "$file"); digest=$(sha256sum "$file"); digest=${{digest%% *}}
  printf '%s\\t%s\\t%s\\n' "$stamp" "$digest" "$file"
done
""")
    choices = dump_choices(listing)
    point = choose("", list(choices))
    dump, digest = choices[point]
    return dump, digest, point


def validate_dump(stage, dump, digest, image):
    """Check integrity, version compatibility and space before touching pgdata."""
    version = remote(f"""cp --reflink=auto --preserve=timestamps -- {shlex.quote(dump)} {stage}/dump.sql.gz
test "$(sha256sum {stage}/dump.sql.gz | cut -d ' ' -f1)" = {shlex.quote(digest)} || {{ echo 'Dump checksum changed while copying; refusing restore.' >&2; exit 1; }}
gzip -t {stage}/dump.sql.gz
available=$(df -B1 --output=avail {stage} | tail -1)
sql=$(gzip -dc {stage}/dump.sql.gz | wc -c)
data=$(du -sb {ROOT}/pgdata | cut -f1)
((available > data * 2 + sql * 3)) || {{ echo "Insufficient free space: $available bytes available; require more than $((data * 2 + sql * 3)) bytes." >&2; exit 1; }}
gzip -dc {stage}/dump.sql.gz > {stage}/dump.sql
chmod 600 {stage}/dump.sql*
grep -q '^-- PostgreSQL database cluster dump$' {stage}/dump.sql || {{ echo 'Selected file is not a pg_dumpall cluster dump.' >&2; exit 1; }}
grep -q '^-- PostgreSQL database cluster dump complete$' {stage}/dump.sql || {{ echo 'Cluster dump completion marker is missing.' >&2; exit 1; }}
sed -n 's/^-- Dumped from database version \\([0-9][0-9]*\\).*/\\1/p' {stage}/dump.sql | sort -u
""").strip()
    actual = run(
        f"docker run --rm --network none --entrypoint postgres {image} --version"
    )
    match = re.search(r"PostgreSQL\) (\d+)", actual)
    if not version.isdecimal() or not match or match[1] != version:
        raise RuntimeError(
            f"PostgreSQL version mismatch or missing version: dump={version!r}, image={actual.strip()!r}"
        )
    return version


def verify_storage():
    """Check storage paths; Task is responsible for checking unused mounts."""
    remote(f"""test -d {ROOT}/pgdata || {{ echo 'Production pgdata is missing; inspect the previous restore and rollback directories.' >&2; exit 1; }}
test "$(realpath -e {ROOT}/pgdata)" = {ROOT}/pgdata || {{ echo 'Production pgdata resolves to a different path.' >&2; exit 1; }}
if mountpoint -q {ROOT}/pgdata; then
  echo 'Production pgdata is a mountpoint; directory replacement is unsafe.' >&2
  exit 1
fi
""")


def backup_current(stage, name):
    """Snapshot current pgdata and verify its Borg backup before selecting a dump.

    Notes
    -----
    Borgmatic's native Borg passthrough reuses configured repository credentials.
    Snapshot, archive ID and verification status are retained alongside the logs.
    """
    snapshot = f"rpool/swarm/postgres@pre-{name}"
    archive = f"pre-{name}"
    remote(f"zfs snapshot {snapshot}\nzfs hold postgres-restore {snapshot}\n")
    print("✓ ZFS snapshot created and held", flush=True)
    result = json.loads(
        remote(
            f"borgmatic --no-color --verbosity -1 borg create --json ::{archive} {ROOT}/.zfs/snapshot/pre-{name}/pgdata\n"
        )
    )
    record = {"snapshot": snapshot, "archive": result["archive"], "verified": False}
    remote(f"cat > {stage}/backup.json <<'JSON'\n{json.dumps(record)}\nJSON\n")
    remote(
        f"borgmatic --no-color --verbosity -1 borg check --verify-data ::{archive}\n"
    )
    info = json.loads(
        remote(f"borgmatic --no-color --verbosity -1 borg info --json ::{archive}\n")
    )
    if (
        len(info["archives"]) != 1
        or info["archives"][0]["id"] != record["archive"]["id"]
    ):
        raise RuntimeError("Current-state Borg archive identity verification failed")
    record["verified"] = True
    remote(f"cat > {stage}/backup.json <<'JSON'\n{json.dumps(record)}\nJSON\n")
    print("✓ Borg archive created and verified", flush=True)


def preserve_original(rollback):
    """Recheck paths and rename original pgdata without overwriting anything."""
    verify_storage()
    confirm("RESTORE")
    remote(f"""test "$(realpath -e {ROOT}/pgdata)" = {ROOT}/pgdata
! mountpoint -q {ROOT}/pgdata
test ! -e {rollback}
mv -T -n {ROOT}/pgdata {rollback}
test ! -e {ROOT}/pgdata
""")
    print("✓ Original pgdata preserved", flush=True)


def restore_cluster(stage, image, container, bootstrap):
    """Initialize fresh production storage and import with native psql.

    Notes
    -----
    No network access or application writers. Failed imports are never retried.
    """
    remote(f"test ! -e {ROOT}/pgdata\nmkdir {ROOT}/pgdata\n")
    run(
        f"docker run -d --name {container} --network none --stop-timeout 120 --mount type=bind,src={VMROOT}/pgdata,dst=/var/lib/postgresql/data/pgdata --mount type=bind,src={stage.replace(ROOT, VMROOT)},dst=/restore --env PGDATA=/var/lib/postgresql/data/pgdata --env POSTGRES_USER={bootstrap} --env POSTGRES_DB=postgres --env POSTGRES_HOST_AUTH_METHOD=trust --env 'POSTGRES_INITDB_ARGS=--auth-local=trust --auth-host=reject' {image} postgres -c listen_addresses="
    )
    for _ in range(150):
        try:
            run(
                f"docker exec {container} bash -c 'test \"$(cat /proc/1/comm)\" = postgres && pg_isready -U {bootstrap}'"
            )
            break
        except subprocess.CalledProcessError:
            time.sleep(2)
    else:
        raise RuntimeError("Fresh PostgreSQL failed to start")
    psql = f"docker exec -i {container} psql -XAt -U {bootstrap} -d postgres -v ON_ERROR_STOP=1"
    if (
        run(
            psql, input="SELECT count(*) FROM pg_database WHERE NOT datistemplate;"
        ).strip()
        != "1"
    ):
        raise RuntimeError("Fresh cluster is populated")
    print("✓ Fresh cluster initialized", flush=True)
    run(
        f"docker exec {container} bash -euc 'psql -X -U {bootstrap} -d postgres -v ON_ERROR_STOP=1 -f /restore/dump.sql > /restore/import.log 2>&1'"
    )
    print("✓ SQL imported", flush=True)


def verify_and_reconcile(container, bootstrap):
    """Verify databases/roles, then reuse the shared credential reconciliation script."""
    psql = f"docker exec -i {container} psql -XAt -U {bootstrap} -d postgres -v ON_ERROR_STOP=1"
    databases = json.loads(
        run(
            psql,
            input="SELECT json_agg(datname ORDER BY datname) FROM pg_database WHERE NOT datistemplate AND datallowconn;",
        )
    )
    roles = json.loads(
        run(
            psql,
            input="SELECT json_agg(rolname ORDER BY rolname) FROM pg_roles WHERE rolcanlogin;",
        )
    )
    if (
        not DATABASES <= set(databases)
        or not DATABASES <= set(roles)
        or run(
            psql, input="SELECT rolsuper FROM pg_roles WHERE rolname='postgres';"
        ).strip()
        != "t"
    ):
        raise RuntimeError("Required databases or roles are missing")
    for database in databases:
        conninfo = shlex.quote(
            "dbname='" + database.replace("\\", "\\\\").replace("'", "\\'") + "'"
        )
        run(
            f"docker exec {container} psql -XAt -U {bootstrap} -d {conninfo} -v ON_ERROR_STOP=1 -c 'SELECT count(*) FROM pg_catalog.pg_class'"
        )
    print("✓ Databases verified", flush=True)
    for role in PASSWORDS:
        secret = f"postgres_{role}_password"
        run(
            f"docker exec -i {container} bash -ec 'umask 077; mkdir -p /run/secrets; cat > /run/secrets/{secret}'",
            input=os.environ[secret.upper()],
        )
    run(
        f"docker cp platform/data/postgres/configs/postgres-reconcile.sh {container}:/run/reconcile.sh"
    )
    run(
        f"docker exec -e PGHOST=/var/run/postgresql -e PGUSER={bootstrap} {container} bash /run/reconcile.sh"
    )
    run(
        # PostgreSQL's initial bootstrap role must remain a superuser.
        f"docker exec {container} psql -X -U postgres -d postgres -v ON_ERROR_STOP=1 -c 'ALTER ROLE {bootstrap} NOLOGIN PASSWORD NULL'"
    )
    print("✓ Credentials reconciled", flush=True)


def main():
    """Select, preserve, restore and verify; the operator deploys applications."""
    os.umask(0o077)
    print("[1/5] Preparing", flush=True)
    if not sys.stdin.isatty():
        raise RuntimeError("An interactive terminal is required")
    for role in PASSWORDS:
        if not os.environ.get(f"POSTGRES_{role.upper()}_PASSWORD"):
            raise RuntimeError(f"Missing SecretSpec credential: {role}")
    image = shlex.quote(
        run("yq -r '.services.server.image' platform/data/postgres/stack.yml").strip()
    )
    stage = remote(
        f"mkdir {ROOT}/.restore-lock\nmktemp -d {ROOT}/restore-XXXXXXXX\n"
    ).strip()
    if not re.fullmatch(ROOT + r"/restore-[a-zA-Z0-9]+", stage):
        raise RuntimeError("Invalid recovery directory")
    name = stage.rsplit("/", 1)[1]
    rollback = ROOT + "/pgdata-before-" + name
    container = "postgres_" + name
    bootstrap = "restore_" + name.rsplit("-", 1)[1].lower()
    step = "[1/5] Preparing"
    try:
        print("✓ Production stopped", flush=True)
        verify_storage()
        print("✓ Storage available", flush=True)
        step = "[2/5] Preserving current state"
        print(f"\n{step}", flush=True)
        backup_current(stage, name)
        step = "[3/5] Select recovery point"
        print(f"\n{step}\n", flush=True)
        dump, digest, point = select_backup(stage)
        version = validate_dump(stage, dump, digest, image)
        print(f"✓ Backup validated (PostgreSQL {version})", flush=True)
        print(
            "WARNING: Keep deployments paused. Restore only trusted SQL. Paperless/Vaultwarden may require matching filesystem recovery points; old pgdata may require crash recovery if reinstated.",
            file=sys.stderr,
            flush=True,
        )
        step = "[4/5] Restoring"
        print(f"\n{step}\nTarget: ALL DATABASES\nRecovery point: {point}\n", flush=True)
        preserve_original(rollback)
        restore_cluster(stage, image, container, bootstrap)
        verify_and_reconcile(container, bootstrap)
        run(f"docker stop --time 120 {container}")
        remote(f"test ! -e {ROOT}/pgdata/postmaster.pid\nrmdir {ROOT}/.restore-lock\n")
        print("✓ PostgreSQL stopped cleanly", flush=True)
        run(f"docker rm {container}")
        print(
            f"\n[5/5] Complete\n\nDATABASE RESTORED\nApplication verification pending.\n\n"
            f"Rollback: {rollback.rsplit('/', 1)[1]}\nEvidence: {name}\n\nNext: task deploy",
            flush=True,
        )
    except (Exception, KeyboardInterrupt):
        print(
            f"FAILED during {step}\n"
            f"Inspect original data at {ROOT}/pgdata or {rollback}; the move may not have occurred.\n"
            f"Recovery files: {stage}\nImport log (if import started): {stage}/import.log\n"
            f"Container (if created): {container}; it may still be running.\n"
            "Keep applications stopped. Nothing was automatically rolled back; preserve files and inspect before retrying.",
            file=sys.stderr,
        )
        raise


if __name__ == "__main__":
    try:
        main()
    except (
        RuntimeError,
        subprocess.CalledProcessError,
        KeyboardInterrupt,
        EOFError,
    ) as error:
        detail = (
            error.stderr.strip()
            if isinstance(error, subprocess.CalledProcessError) and error.stderr
            else str(error)
        )
        for role in PASSWORDS:
            password = os.environ.get(f"POSTGRES_{role.upper()}_PASSWORD")
            if password:
                detail = detail.replace(password, "[REDACTED]")
        print(f"ERROR: {detail}", file=sys.stderr)
        sys.exit(1)
