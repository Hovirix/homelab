#!/usr/bin/env bash
set -euo pipefail

: "${INCUS_CLIENT_CERT:?required}"
umask 077

build_dir=".artifacts/incusos"
seed_dir="$build_dir/seed"
mkdir -p "$seed_dir"

# Copy the installation, network, and storage configuration unchanged.
cp infrastructure/incusos/{install,network,storage}.yaml "$seed_dir/"

# Trust the public client certificate provided by SecretSpec.
yq '.preseed.certificates[0].certificate = load_str(strenv(INCUS_CLIENT_CERT))' \
  infrastructure/incusos/incus.yaml >"$seed_dir/incus.yaml"

# Package the seed and build the USB image with the upstream flasher.
tar -C "$seed_dir" -cf "$build_dir/seed.tar" install.yaml incus.yaml network.yaml storage.yaml

cd "$build_dir"
exec flasher-tool --format img --channel stable --seed seed.tar
