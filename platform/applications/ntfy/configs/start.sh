#!/bin/sh
set -eu

# ntfy has no _FILE options for database credentials, users, tokens, or VAPID keys.
export NTFY_DATABASE_URL
NTFY_DATABASE_URL="$(cat /run/secrets/ntfy_database_url)"

password="$(cat /run/secrets/ntfy_reader_password)"
hash="$(printf '%s\n%s\n' "$password" "$password" | ntfy user hash)"

NTFY_AUTH_USERS="reader:${hash}:user"
NTFY_AUTH_TOKENS=""

for name in grafana authentik; do
  token="$(cat "/run/secrets/ntfy_${name}_token")"
  hash="$(printf '%s\n%s\n' "$token" "$token" | ntfy user hash)"

  NTFY_AUTH_USERS="${NTFY_AUTH_USERS},${name}:${hash}:user"
  NTFY_AUTH_TOKENS="${NTFY_AUTH_TOKENS:+${NTFY_AUTH_TOKENS},}${name}:${token}"
done

export NTFY_AUTH_USERS NTFY_AUTH_TOKENS

exec ntfy serve --config /run/secrets/ntfy_web_push_keys
