#!/usr/bin/env bash
set -euo pipefail

build_dir="infrastructure/opentofu/stacks/incus/build"
mkdir -p "$build_dir"

# Download, verify the signature, and decompress the official FCOS disk.
disk_image=$(coreos-installer download \
  --stream stable \
  --architecture x86_64 \
  --platform proxmoxve \
  --format qcow2.xz \
  --decompress \
  --directory "$build_dir")

release=$(basename "$disk_image")
release=${release#fedora-coreos-}
release=${release%-proxmoxve.x86_64.qcow2}
mv "$disk_image" "$build_dir/fcos-proxmoxve.qcow2"

# Package the metadata required to import the disk into Incus.
jq --null-input --arg release "$release" --argjson created "$(date +%s)" \
  '{
    architecture: "x86_64",
    creation_date: $created,
    properties: {
      os: "Fedora",
      variant: "coreos",
      release: $release,
      description: "Fedora CoreOS \($release)"
    }
  }' > "$build_dir/metadata.yaml"

tar -C "$build_dir" -cf "$build_dir/metadata.tar" metadata.yaml
