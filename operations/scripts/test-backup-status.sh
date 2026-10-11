#!/usr/bin/env bash
set -euo pipefail

script="$(<infrastructure/ansible/roles/backup/templates/offsite-backup.sh.j2)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/status"
# shellcheck disable=SC2016
sed '/^{% raw %}$/d; /^{% endraw %}$/d; s|/rpool/swarm/backup-status|SET_STATUS_DIR|g; s|SET_STATUS_DIR|'"$tmp/status"'|g; s|install -d -m 0755 -o root -g root "$status_dir"|mkdir -p "$status_dir"|; s|/run/swarm-zfs-snapshot.lock|LOCKFILE|g; s|LOCKFILE|'"$tmp/lock"'|g; s|/usr/local/sbin/swarm-zfs-snapshot|'"$tmp/bin/snapshot"'|g; s|borgmatic|'"$tmp/bin/borgmatic"'|g; s|if capacity=.*|if false; then|' <<<"$script" >"$tmp/backup"
chmod +x "$tmp/backup"
printf '#!/usr/bin/env bash\nexit 0\n' >"$tmp/bin/snapshot"
printf "#!/usr/bin/env bash\n[[ \$1 == repo-info ]] && exit 0\nexit 1\n" >"$tmp/bin/borgmatic"
chmod +x "$tmp/bin/"*
set +e
"$tmp/backup"
rc=$?
set -e
[[ $rc -eq 1 ]]
[[ "$(awk '$1 == "backup_last_status" {print $2}' "$tmp/status/backup.prom")" == 0 ]]

printf "#!/usr/bin/env bash\n[[ \$1 == repo-info ]] && exit 0\nexit 0\n" >"$tmp/bin/borgmatic"
chmod +x "$tmp/bin/borgmatic"
"$tmp/backup"
[[ "$(awk '$1 == "backup_last_status" {print $2}' "$tmp/status/backup.prom")" == 1 ]]
[[ "$(awk '$1 == "backup_last_success_timestamp_seconds" {print $2}' "$tmp/status/backup.prom")" -gt 0 ]]
