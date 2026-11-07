#!/usr/bin/env python3
"""Interactive recovery. Check writers, preserve data, restore, verify."""

import json
import os
import re
import shlex
import subprocess
import sys
import time
from datetime import datetime, timezone

from secretspec import SecretSpecError, resolve

ROOT = "/rpool/swarm/postgres"
VMROOT = "/var/mnt/swarm/postgres"
DATABASES = {"postgres", "authentik", "grafana", "paperless", "vaultwarden"}
PASSWORDS = ("superuser", "authentik", "grafana", "paperless", "vaultwarden")


def run(command, *, input=None, capture=True):
    """Run a native CLI; stop on failure."""
    return subprocess.run(
        shlex.split(command), input=input, text=True, capture_output=capture, check=True
    ).stdout


def remote(script):
    """Run host commands with private file permissions."""
    try:
        return run(
            f"ssh -T -o BatchMode=yes -o ConnectTimeout=10 {shlex.quote(os.environ['PVE'])} 'bash -seuo pipefail'",
            input="umask 077\n"
            + 'trap \'printf "Host command failed: line %s, exit %s\\n" "$LINENO" "$?" >&2\' ERR\n'
            + script,
        )
    except subprocess.CalledProcessError as error:
        detail = (error.stderr or "").strip() or f"exit status {error.returncode}"
        raise RuntimeError(f"Restore host failed: {detail}") from error


def choose(prompt, options, *, multiple=False, cancel=False):
    """Require an explicit selection; cancel only before recovery starts."""
    if not options:
        raise RuntimeError("No recovery points found")
    if prompt:
        print(f"\n{prompt}")
    for index, option in enumerate(options, 1):
        print(f"{index}. {option}")
    question = "Choose numbers, separated by spaces: " if multiple else "Choose one: "
    if cancel:
        question = f"Choose [1–{len(options)}, Enter to cancel]: "
    while True:
        answer = input(question).split()
        if not answer and cancel:
            raise SystemExit(0)
        if (
            answer
            and (multiple or len(answer) == 1)
            and all(
                number.isdecimal()
                and len(number) <= len(str(len(options)))
                and 1 <= int(number) <= len(options)
                for number in answer
            )
        ):
            selected = list(
                dict.fromkeys(options[int(number) - 1] for number in answer)
            )
            return selected if multiple else selected[0]
        print("Invalid selection.")


def manager_host(hosts):
    """Find a reachable, active Swarm manager."""
    for host in hosts:
        try:
            state = run(
                f"docker --host {shlex.quote(host)} info --format '{{{{.Swarm.LocalNodeState}}}}|{{{{.Swarm.ControlAvailable}}}}'"
            )
        except subprocess.CalledProcessError:
            continue
        if state.strip() == "active|true":
            return host
    raise RuntimeError("No active Swarm manager reachable")


def assert_mounts_unused(mounts, datasets):
    """Reject writable mounts at, above, or below selected datasets."""
    for mount in mounts.splitlines():
        if not mount:
            continue
        mount = mount.rstrip("/") or "/"
        for dataset in datasets:
            target = f"/var/mnt/swarm/{dataset}"
            if (
                mount == "/"
                or mount == target
                or mount.startswith(target + "/")
                or target.startswith(mount + "/")
            ):
                raise RuntimeError(
                    f"Dataset in use: {dataset}\nWritable mount: {mount}\nRemove its services and containers first."
                )


def assert_unused(datasets):
    """Check service specs and running containers on every manager; fail closed."""
    if not datasets or any(
        not re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9_-]*", dataset) for dataset in datasets
    ):
        raise RuntimeError("Invalid dataset selection")
    hosts = shlex.split(os.environ["MANAGER_HOSTS"])
    manager = manager_host(hosts)
    docker = f"docker --host {shlex.quote(manager)}"
    services = run(f"{docker} service ls -q").split()
    if services:
        mounts = run(
            f"{docker} service inspect --format '{{{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}}}{{{{if not .ReadOnly}}}}{{{{println .Source}}}}{{{{end}}}}{{{{end}}}}' {shlex.join(services)}"
        )
        assert_mounts_unused(mounts, datasets)
    for host in hosts:
        docker = f"docker --host {shlex.quote(host)}"
        containers = run(f"{docker} ps -q").split()
        if containers:
            mounts = run(
                f"{docker} inspect --format '{{{{range .Mounts}}}}{{{{if .RW}}}}{{{{println .Source}}}}{{{{end}}}}{{{{end}}}}' {shlex.join(containers)}"
            )
            assert_mounts_unused(mounts, datasets)
    return manager


def dated_choices(points):
    """Keep exact recovery-point identities behind UTC labels, newest first."""
    choices = {}
    for stamp, name in sorted(
        (
            (stamp.replace(tzinfo=stamp.tzinfo or timezone.utc), name)
            for stamp, name in points
        ),
        reverse=True,
    ):
        label = stamp.astimezone(timezone.utc).strftime("%Y-%m-%d %H:%M")
        if label in choices:
            label += f" ({name})"
        choices[label] = name
    return choices


def select_archive():
    """Select an archive from the single configured Borg repository."""
    repositories = json.loads(
        remote("borgmatic --no-color --verbosity -1 repo-list --json\n")
    )
    if not isinstance(repositories, list) or len(repositories) != 1:
        raise RuntimeError("Expected one Borg repository")
    choices = dated_choices(
        (
            datetime.fromisoformat(archive["time"]),
            archive["name"],
        )
        for archive in repositories[0]["archives"]
    )
    point = choose("Backup — UTC, newest first", list(choices))
    return choices[point], point


def restore_host(mode):
    """Select exact recovery points; check writers; confirm changes on PVE."""
    if mode == "local":
        listing = remote("zfs list -H -o name -d 1 rpool/swarm\n")
        dataset = choose(
            "Dataset",
            sorted(
                name.removeprefix("rpool/swarm/")
                for name in listing.splitlines()
                if name.startswith("rpool/swarm/")
            ),
        )
        datasets = [dataset]
        assert_unused(datasets)
        print("\nChecking writers... OK")
        listing = remote(
            f"zfs list -H -p -t snapshot -o name,creation -S creation {shlex.quote('rpool/swarm/' + dataset)}\n"
        )
        choices = dated_choices(
            (datetime.fromtimestamp(int(stamp), timezone.utc), name)
            for name, stamp in (line.split("\t") for line in listing.splitlines())
        )
        point = choose("Snapshot — UTC, newest first", list(choices))
        arguments = [dataset, choices[point], point + " UTC"]
    else:
        archive, point = select_archive()
        listing = remote(
            f"borgmatic --no-color --verbosity -1 list --archive {shlex.quote(archive)} --short\n"
        )
        available = sorted(
            set(
                re.findall(
                    r"^rpool/swarm/([a-zA-Z0-9][a-zA-Z0-9_-]*)(?:/|$)",
                    listing,
                    re.MULTILINE,
                )
            )
        )
        selected = choose(
            "Datasets in this backup", available, multiple=mode == "offsite"
        )
        datasets = selected if mode == "offsite" else [selected]
        if mode == "offsite":
            assert_unused(datasets)
            print("\nChecking writers... OK")
        arguments = [archive, point + " UTC", *datasets]
    command = shlex.join(["/usr/local/sbin/restore", mode, *arguments])
    run(
        f"ssh -tt -o BatchMode=yes -o ConnectTimeout=10 {shlex.quote(os.environ['PVE'])} {shlex.quote(command)}",
        capture=False,
    )


def confirm(word):
    """Require the exact confirmation word before changing production storage."""
    if input(f"Type {word} to confirm: ") != word:
        raise RuntimeError("Cancelled")
    print()


def dump_choices(listing):
    """Map labels to paths/checksums; newest first, duplicate dumps removed."""
    choices, seen = {}, set()
    for stamp, digest, path in sorted(
        (line.split("\t") for line in listing.splitlines()),
        key=lambda row: (-int(row[0]), row[2]),
    ):
        if digest not in seen:
            seen.add(digest)
            date = datetime.fromtimestamp(int(stamp), timezone.utc).strftime(
                "%Y-%m-%d %H:%M"
            )
            label = date if date not in choices else f"{date} ({path})"
            choices[label] = (path, digest)
    return choices


def select_backup(stage):
    """Select a local dump or extract Borg dumps without replacing live files."""
    source = ROOT + "/backups"
    selected_source = choose("", ["Local dumps", "Off-site backups"])
    if selected_source == "Off-site backups":
        selected_archive, _ = select_archive()
        archive = shlex.quote(selected_archive)
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
    point = choose("Dump — UTC, newest first", list(choices))
    dump, digest = choices[point]
    return dump, digest, point + " UTC"


def validate_dump(stage, dump, digest, image):
    """Check integrity, version compatibility and space before touching pgdata."""
    version = remote(f"""cp --reflink=auto --preserve=timestamps -- {shlex.quote(dump)} {stage}/dump.sql.gz
test "$(sha256sum {stage}/dump.sql.gz | cut -d ' ' -f1)" = {shlex.quote(digest)} || {{ echo 'Dump checksum changed; restore blocked.' >&2; exit 1; }}
gzip -t {stage}/dump.sql.gz
available=$(df -B1 --output=avail {stage} | tail -1)
sql=$(gzip -dc {stage}/dump.sql.gz | wc -c)
data=$(du -sb {ROOT}/pgdata | cut -f1)
((available > data * 2 + sql * 3)) || {{ echo "Not enough space: $available bytes free; need more than $((data * 2 + sql * 3))." >&2; exit 1; }}
gzip -dc {stage}/dump.sql.gz > {stage}/dump.sql
chmod 600 {stage}/dump.sql*
grep -q '^-- PostgreSQL database cluster dump$' {stage}/dump.sql || {{ echo 'Not a pg_dumpall cluster dump.' >&2; exit 1; }}
grep -q '^-- PostgreSQL database cluster dump complete$' {stage}/dump.sql || {{ echo 'Cluster dump is incomplete.' >&2; exit 1; }}
sed -n 's/^-- Dumped from database version \\([0-9][0-9]*\\).*/\\1/p' {stage}/dump.sql | sort -u
""").strip()
    actual = run(
        f"docker run --rm --network none --entrypoint postgres {image} --version"
    )
    match = re.search(r"PostgreSQL\) (\d+)", actual)
    if not version.isdecimal() or not match or match[1] != version:
        raise RuntimeError(
            f"PostgreSQL version missing or mismatched: dump={version!r}, image={actual.strip()!r}"
        )
    print(
        "\nChecksum... OK\nDump format... OK\nPostgreSQL version... OK\nFree space... OK",
        flush=True,
    )
    return version


def verify_storage():
    """Check storage paths after the shared unused-mount preflight."""
    remote(f"""test -d {ROOT}/pgdata || {{ echo 'pgdata missing. Check previous restore directories.' >&2; exit 1; }}
test "$(realpath -e {ROOT}/pgdata)" = {ROOT}/pgdata || {{ echo 'pgdata resolves outside its expected path.' >&2; exit 1; }}
if mountpoint -q {ROOT}/pgdata; then
  echo 'pgdata is a mountpoint; replacement blocked.' >&2
  exit 1
fi
""")


def backup_current(stage, name):
    """Hold a ZFS snapshot; create and verify its Borg archive; record evidence."""
    snapshot = f"rpool/swarm/postgres@pre-{name}"
    archive = f"pre-{name}"
    remote(f"zfs snapshot {snapshot}\nzfs hold postgres-restore {snapshot}\n")
    print("ZFS snapshot... held", flush=True)
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
        raise RuntimeError("Current-data Borg archive ID mismatch")
    record["verified"] = True
    remote(f"cat > {stage}/backup.json <<'JSON'\n{json.dumps(record)}\nJSON\n")
    print("Off-site backup... verified", flush=True)


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
    print("Previous data... preserved", flush=True)


def restore_cluster(stage, image, container, bootstrap):
    """Import once into a fresh, network-isolated PostgreSQL container."""
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
        raise RuntimeError("Restore PostgreSQL failed to start")
    psql = f"docker exec -i {container} psql -XAt -U {bootstrap} -d postgres -v ON_ERROR_STOP=1"
    if (
        run(
            psql, input="SELECT count(*) FROM pg_database WHERE NOT datistemplate;"
        ).strip()
        != "1"
    ):
        raise RuntimeError("Restore cluster already contains databases")
    run(
        f"docker exec {container} bash -euc 'psql -X -U {bootstrap} -d postgres -v ON_ERROR_STOP=1 -f /restore/dump.sql > /restore/import.log 2>&1'"
    )
    print("SQL import... complete", flush=True)


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
    print("Database checks... passed", flush=True)
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
    print("Current credentials... applied", flush=True)


def restore_postgres():
    """Select, preserve, restore and verify; the operator deploys applications."""
    values = resolve(
        profile="production", scope="swarm", reason="restore PostgreSQL credentials"
    ).fields()
    for role in PASSWORDS:
        key = f"POSTGRES_{role.upper()}_PASSWORD"
        if not values.get(key):
            raise RuntimeError(f"Missing PostgreSQL password: {role}")
        os.environ[key] = values[key]
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
    step = "[1/5] Check"
    try:
        verify_storage()
        print("Storage... OK", flush=True)
        step = "[2/5] Back up current data"
        print(f"\n{step}", flush=True)
        backup_current(stage, name)
        step = "[3/5] Choose dump"
        print(f"\n{step}\n", flush=True)
        dump, digest, point = select_backup(stage)
        validate_dump(stage, dump, digest, image)
        step = "[4/5] Restore"
        print(
            f"\n{step}\nScope: ALL databases\nDump:  {point}\n\n"
            "Use trusted SQL only.\n"
            "Paperless/Vaultwarden files must match the restored databases.\n",
            flush=True,
        )
        preserve_original(rollback)
        restore_cluster(stage, image, container, bootstrap)
        verify_and_reconcile(container, bootstrap)
        run(f"docker stop --time 120 {container}")
        remote(f"test ! -e {ROOT}/pgdata/postmaster.pid\nrmdir {ROOT}/.restore-lock\n")
        print("PostgreSQL... stopped cleanly", flush=True)
        run(f"docker rm {container}")
        print(
            f"\n[5/5] Restore complete\nApplication checks: PENDING\n\n"
            f"Previous data: {rollback}\nRestore logs:  {stage}\n\n"
            "Previous data may need crash recovery if reused.\n"
            "Next: task deploy, then verify applications.",
            flush=True,
        )
    except (Exception, KeyboardInterrupt):
        print(
            f"RESTORE FAILED: {step}\n"
            "Keep services stopped. Do not deploy.\n"
            "No automatic rollback. Inspect before retrying.\n\n"
            "Previous data may need crash recovery if reused.\n"
            f"Original data: {ROOT}/pgdata OR {rollback} (move may not have completed)\n"
            f"Restore files: {stage}\nImport log: {stage}/import.log (if created)\n"
            f"Container: {container} (may still be running)",
            file=sys.stderr,
        )
        raise


def main():
    """Select one recovery operation."""
    os.umask(0o077)
    if not sys.stdin.isatty():
        raise RuntimeError("Interactive terminal required")
    modes = {
        "Local snapshot": "local",
        "Off-site backup": "offsite",
        "Extract backup only": "extract",
        "PostgreSQL dump — ALL databases": "postgres",
    }
    mode = modes[choose("Restore", list(modes), cancel=True)]
    if mode == "postgres":
        print(
            "\nPOSTGRESQL RESTORE\nScope: ALL databases\n",
            flush=True,
        )
        print("[1/5] Check", flush=True)
        os.environ["DOCKER_HOST"] = assert_unused(["postgres"])
        print("Writers... none found", flush=True)
        restore_postgres()
    else:
        restore_host(mode)


if __name__ == "__main__":
    try:
        main()
    except (
        RuntimeError,
        ValueError,
        SecretSpecError,
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
