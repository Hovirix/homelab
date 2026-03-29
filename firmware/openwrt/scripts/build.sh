#!/usr/bin/env bash
set -euo pipefail

IMAGE_BUILDER="openwrt-imagebuilder-mediatek-filogic.Linux-x86_64"
PROFILE="glinet_gl-mt6000"
PACKAGES="adguardhome irqbalance map tailscale"
FILES="../files"

if [ ! -d "$IMAGE_BUILDER" ]; then
  printf 'Error: image builder directory "%s" not found. Run ./scripts/setup.sh first.\n' "$IMAGE_BUILDER" >&2
  exit 1
fi

make -C "$IMAGE_BUILDER" image \
  PROFILE="$PROFILE" \
  PACKAGES="$PACKAGES" \
  FILES="$FILES"
