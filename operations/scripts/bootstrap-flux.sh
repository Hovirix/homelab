#!/usr/bin/env bash

set -euo pipefail

flux bootstrap github \
  --owner=hovirix \
  --repository=homelab \
  --branch=main \
  --path=platform/clusters/prod \
  --personal \
  --private=false
