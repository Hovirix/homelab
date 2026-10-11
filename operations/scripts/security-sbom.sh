#!/usr/bin/env bash

set -euo pipefail

sbom_dir=".artifacts/security/sbom"

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

  trivy image --scanners vuln --format cyclonedx --output "$sbom_dir/$slug.cdx.json" "$image"
done <<<"$images"
