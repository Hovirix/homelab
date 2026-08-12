#!/usr/bin/env bash

set -euo pipefail

export PAPERLESS_SOCIALACCOUNT_PROVIDERS
PAPERLESS_SOCIALACCOUNT_PROVIDERS="$(python3 <<'PY'
import json
from pathlib import Path

print(json.dumps({
    "openid_connect": {
        "APPS": [
            {
                "provider_id": "authentik",
                "name": "authentik",
                "client_id": Path("/run/secrets/oauth_paperless_client_id").read_text(),
                "secret": Path("/run/secrets/oauth_paperless_client_secret").read_text(),
                "settings": {
                    "server_url": "https://authentik.home.hovirix.dev/application/o/paperless/.well-known/openid-configuration",
                },
            },
        ],
    },
}))
PY
)"

exec /init
