#!/usr/bin/env bash
set -euo pipefail

dir=".artifacts/security/sarif/images"
mkdir -p "$dir"
rm -f "$dir"/*.sarif

images="$(
  find platform -type f -name stack.yml -exec \
    yq -N -r '.services[]? | select(.image != null) | .image' {} + |
    sort -u
)"

[[ -n "$images" ]] || {
  echo "No images found" >&2
  exit 1
}

failed=0

while IFS= read -r image; do
  name="$(printf '%s' "$image" | tr '/:@' '_')"
  report="$dir/$name.sarif"

  trivy image \
    --scanners vuln \
    --severity HIGH,CRITICAL \
    --exit-code 0 \
    --format sarif \
    --output "$report" \
    "$image"

  SARIF_ID="images/$name/" yq -i -o=json \
    '.runs[0].automationDetails.id = strenv(SARIF_ID)' "$report"

  count="$(yq -r '.runs[0].results | length' "$report")"
  echo "$image: $count vulnerabilities"

  if ((count > 0)); then
    failed=1
  fi
done <<<"$images"

exit "$failed"
