#!/usr/bin/env bash

set -euo pipefail

sbom_dir=".artifacts/sbom"

mkdir -p "$sbom_dir"
rm -f "$sbom_dir"/*.cdx.json

images="$(
  find platform -type f -name stack.yml -exec \
    yq -N -r '.services[]? | select(.image != null) | .image' {} + |
    sort -u
)"

if [[ -z "$images" ]]; then
  printf 'No images found\n' >&2
  exit 1
fi

while IFS= read -r image; do
  slug="$(printf '%s' "$image" | tr '/:@' '_')"

  syft "$image" --output "cyclonedx-json=$sbom_dir/$slug.cdx.json"

  printf '✓ %s\n' "${image%@sha256:*}"
done <<<"$images"
