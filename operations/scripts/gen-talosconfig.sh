#!/usr/bin/env bash

set -euo pipefail

config_file="${1:?missing config file}"
sops_file="${2:?missing sops file}"
output_dir="${3:?missing output dir}"

cluster_name="$(yq e -r '.cluster.name' "$config_file")"
domain="$(yq e -r '.domain' "$config_file")"
bootstrap_node="$(yq e -r '.cluster.bootstrap_node' "$config_file")"
talos_version="$(yq e -r '.cluster.talos_version' "$config_file")"
kubernetes_version="$(yq e -r '.cluster.kubernetes_version' "$config_file")"

cluster_endpoint="https://${cluster_name}.${domain}:6443"
bootstrap_hostname="$(yq e -r ".nodes.${bootstrap_node}.name" "$config_file").${domain}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

install -d -m 700 "$output_dir"

sops -d --extract '["talos"]["machine_secrets"]' "$sops_file" >"$tmpdir/machine-secrets.yaml"

talosctl gen config "$cluster_name" "$cluster_endpoint" \
  --with-secrets "$tmpdir/machine-secrets.yaml" \
  --talos-version "$talos_version" \
  --kubernetes-version "$kubernetes_version" \
  --output-types talosconfig \
  --output "$output_dir/talosconfig" \
  --force

mapfile -t controlplane_hosts < <(
  yq e -r ".nodes | to_entries | .[] | select(.value.role == \"controlplane\") | .value.name + \".${domain}\"" "$config_file"
)

talosctl config endpoint "${controlplane_hosts[@]}" \
  --talosconfig "$output_dir/talosconfig"

talosctl config node "$bootstrap_hostname" \
  --talosconfig "$output_dir/talosconfig"

chmod 600 "$output_dir/talosconfig"
