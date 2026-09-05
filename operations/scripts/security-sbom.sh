#!/usr/bin/env bash

set -euo pipefail

sbom_dir=".artifacts/sbom"
index="$sbom_dir/index.tsv"

mkdir -p "$sbom_dir"
rm -f "$sbom_dir"/*.cdx.json "$index"

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
  file="$(printf '%s' "$image" | sha256sum | cut -c1-12)"
  sbom="$sbom_dir/$file.cdx.json"

  syft "$image" --output "cyclonedx-json=$sbom"

  printf '%s\t%s\n' "$image" "$sbom" >>"$index"
  printf '✓ %s\n' "${image%@sha256:*}"
done <<<"$images"
