#!/usr/bin/env bash
set -euo pipefail
umask 077

case "${1:-}" in
  backup)
    destination="secrets/incusos-backup.tar.gz.sops"
    input_type="binary"
    output_type="json"
    ;;
  keys)
    destination="secrets/incusos-security.sops.yaml"
    input_type="yaml"
    output_type="yaml"
    ;;
  *)
    printf 'Usage: %s {backup|keys}\n' "$0" >&2
    exit 1
    ;;
esac

temporary=$(mktemp -d)
encrypted=""
cleanup() {
  rm -f -- "$temporary/export"
  rmdir -- "$temporary"
  if [[ -n "$encrypted" ]]; then
    rm -f -- "$encrypted"
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if [[ "$1" == backup ]]; then
  incus admin os system backup incus: "$temporary/export"
else
  incus admin os system security show incus: --format=yaml >"$temporary/export"
fi
test -s "$temporary/export"

encrypted=$(mktemp secrets/.incusos-XXXXXX)
sops --encrypt --config .sops.yaml --filename-override "$destination" \
  --input-type "$input_type" --output-type "$output_type" \
  "$temporary/export" >"$encrypted"
mv -- "$encrypted" "$destination"
if [[ "$1" == keys ]]; then
  incus admin os system security retrieved incus:
fi
printf 'Saved %s\n' "$destination"
