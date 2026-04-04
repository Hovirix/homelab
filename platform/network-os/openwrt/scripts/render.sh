#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="/tmp"
NETWORK_SECRET="../../security/secrets/network-os/network.sops.yaml"
WIRELESS_SECRET="../../security/secrets/network-os/wireless.sops.yaml"

sops -d "$NETWORK_SECRET" >"$BUILD_DIR/network.yaml"
sops -d "$WIRELESS_SECRET" >"$BUILD_DIR/wireless.yaml"

gomplate

trap 'rm -f "$BUILD_DIR/network.yaml" "$BUILD_DIR/wireless.yaml"' EXIT
