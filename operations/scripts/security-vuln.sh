#!/usr/bin/env bash

set -uo pipefail

sbom_dir=".artifacts/sbom"
report_dir=".artifacts/security/grype"
index="$sbom_dir/index.tsv"

if [[ ! -f "$index" ]]; then
  printf 'SBOM index not found\n' >&2
  exit 1
fi

mkdir -p "$report_dir"
rm -f "$report_dir"/*.json

green=$'\033[32m'
red=$'\033[31m'
yellow=$'\033[33m'
reset=$'\033[0m'

failed=0
total=0

while IFS=$'\t' read -r image sbom; do
  total=$((total + 1))

  name="$(basename "$sbom" .cdx.json)"
  report="$report_dir/$name.json"

  grype "sbom:$sbom" --file "$report" >/dev/null 2>&1 || true

  if ! jq -e . "$report" >/dev/null 2>&1; then
    printf '%s✗%s %s  scan failed\n' \
      "$red" "$reset" "${image%@sha256:*}"
    failed=$((failed + 1))
    continue
  fi

  critical="$(
    jq '[.matches[] | select(.vulnerability.severity == "Critical")] | length' "$report"
  )"

  high="$(
    jq '[.matches[] | select(.vulnerability.severity == "High")] | length' "$report"
  )"

  medium="$(
    jq '[.matches[] | select(.vulnerability.severity == "Medium")] | length' "$report"
  )"

  image="${image%@sha256:*}"

  if ((critical > 0 || high > 0)); then
    printf '%s✗%s %s  %s%d critical%s · %s%d high%s · %s%d medium%s\n' \
      "$red" "$reset" "$image" \
      "$red" "$critical" "$reset" \
      "$red" "$high" "$reset" \
      "$yellow" "$medium" "$reset"

    failed=$((failed + 1))
  else
    printf '%s✓%s %s  %s%d medium%s\n' \
      "$green" "$reset" "$image" \
      "$yellow" "$medium" "$reset"
  fi
done <"$index"

if ((failed > 0)); then
  printf '\n%s✗ FAILED%s  %d/%d images contain High/Critical vulnerabilities\n' \
    "$red" "$reset" "$failed" "$total"
  exit 1
fi

printf '\n%s✓ PASSED%s  no High/Critical vulnerabilities found\n' \
  "$green" "$reset"
