#!/usr/bin/env bash

set -uo pipefail

sbom_dir=".artifacts/security/sbom"
report_dir=".artifacts/security/vuln"

mkdir -p "$report_dir"
rm -f "$report_dir"/*.json

failed=0
for sbom in "$sbom_dir"/*.cdx.json; do
  if [[ ! -f "$sbom" ]]; then
    printf 'No SBOMs found\n' >&2
    exit 1
  fi

  name="$(basename "$sbom" .cdx.json)"
  report="$report_dir/$name.json"
  if trivy sbom --severity HIGH,CRITICAL --exit-code 1 --format json --output "$report" "$sbom"; then
    continue
  fi

  if [[ -s "$report" ]]; then
    printf 'High/Critical vulnerabilities: %s\n' "$name" >&2
    failed=1
  else
    printf 'Scan failed: %s\n' "$name" >&2
    exit 1
  fi
done

exit "$failed"
