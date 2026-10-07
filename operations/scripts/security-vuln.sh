#!/usr/bin/env bash

set -uo pipefail

sbom_dir=".artifacts/sbom"
report_dir=".artifacts/security/grype"

mkdir -p "$report_dir"
rm -f "$report_dir"/*.json

failed=0
total=0

for sbom in "$sbom_dir"/*.cdx.json; do
  if [[ ! -f "$sbom" ]]; then
    printf 'No SBOMs found\n' >&2
    exit 1
  fi

  total=$((total + 1))

  name="$(basename "$sbom" .cdx.json)"
  report="$report_dir/$name.json"
  image="$(jq -r '.metadata.component.name // empty' "$sbom" 2>/dev/null)"
  [[ -n $image ]] || image="$name"

  if grype "sbom:$sbom" --fail-on high --file "$report" >/dev/null 2>&1; then
    printf '✓ %s\n' "${image%@sha256:*}"
  else
    printf '✗ %s\n' "${image%@sha256:*}"
    failed=$((failed + 1))
  fi
done

if ((failed > 0)); then
  printf '\n✗ FAILED  %d/%d images contain High/Critical vulnerabilities\n' \
    "$failed" "$total"
  exit 1
fi

printf '\n✓ PASSED  no High/Critical vulnerabilities found\n'
