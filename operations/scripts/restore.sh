#!/usr/bin/env bash
set -euo pipefail

host='root@pve1.home.hovirix.dev'
parent='rpool/swarm'
lock='/run/swarm-zfs-snapshot.lock'

ssh_opts=(
  -o BatchMode=yes
  -o ConnectTimeout=10
)

# Select stack
dataset_output=$(
  ssh "${ssh_opts[@]}" "$host" \
    "zfs list -H -o name -d 1 '$parent' | sed -n 's#^$parent/##p' | sort"
)

[[ -n $dataset_output ]] || {
  echo 'No Swarm datasets found.'
  exit 1
}

mapfile -t stacks <<<"$dataset_output"

echo 'Select stack:'
PS3='Stack: '

select stack in "${stacks[@]}"; do
  [[ -n $stack ]] && break
  echo 'Invalid selection.'
done

dataset="$parent/$stack"

# Select snapshot
snapshot_output=$(
  ssh "${ssh_opts[@]}" "$host" \
    "zfs list -H -t snapshot -o name -S creation '$dataset' |
     grep -F '$dataset@auto-' || true"
)

[[ -n $snapshot_output ]] || {
  echo "No recovery points found for $stack."
  exit 1
}

mapfile -t snapshots <<<"$snapshot_output"

echo
echo "Available recovery points for $stack:"
PS3='Snapshot: '

select snapshot in "${snapshots[@]}"; do
  [[ -n $snapshot ]] && break
  echo 'Invalid selection.'
done

snapshot_name="${snapshot#"$dataset@"}"

# Confirm
echo
echo 'Restore summary:'
echo "  Stack:    $stack"
echo "  Snapshot: $snapshot_name"

echo
echo 'WARNING:'
echo "  The $stack stack must be stopped."
echo '  Data written after this snapshot will be lost.'
echo '  Newer snapshots for this dataset will be destroyed.'

if [[ $stack == postgres ]]; then
  echo
  echo 'PostgreSQL: this rolls back the entire cluster.'
  echo 'Prefer database-aware recovery for row/table/database incidents.'
fi

echo
read -r -p 'Type "restore" to continue: ' confirmation

[[ $confirmation == restore ]] || {
  echo 'Restore cancelled.'
  exit 1
}

# Restore
ssh "${ssh_opts[@]}" "$host" \
  "flock -n '$lock' zfs rollback -r '$snapshot'"

echo
echo 'Restore complete:'
echo "  Stack:    $stack"
echo "  Snapshot: $snapshot_name"
