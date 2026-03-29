#!/usr/bin/env bash
set -euo pipefail

IMAGE_BUILDER="openwrt-imagebuilder-mediatek-filogic.Linux-x86_64"
ARCHIVE="$IMAGE_BUILDER.tar.zst"
URL="https://downloads.openwrt.org/snapshots/targets/mediatek/filogic/$ARCHIVE"

if [ -d "$IMAGE_BUILDER" ]; then
  exit 0
fi

if [ ! -f "$ARCHIVE" ]; then
  wget -O "$ARCHIVE" "$URL"
fi

tar --zstd -xf "$ARCHIVE"

[ -d "$IMAGE_BUILDER" ]
