#!/usr/bin/env bash

set -euo pipefail

config_file="${1:?missing config file}"
output_dir="${2:?missing output dir}"

domain="$(yq e -r '.domain' "$config_file")"
bootstrap_node="$(yq e -r '.cluster.bootstrap_node' "$config_file")"
bootstrap_hostname="$(yq e -r ".nodes.${bootstrap_node}.name" "$config_file").${domain}"

talosctl kubeconfig "$output_dir/kubeconfig" \
  --merge=false \
  --force \
  --talosconfig "$output_dir/talosconfig" \
  --nodes "$bootstrap_hostname" \
  --endpoints "$bootstrap_hostname"

chmod 600 "$output_dir/kubeconfig"
