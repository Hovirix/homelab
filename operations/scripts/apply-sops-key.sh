#!/usr/bin/env bash

set -euo pipefail

sops -d ./secrets/platform.sops.yaml | yq ".flux.sops_age_key" |
  kubectl create secret generic sops-age \
    --namespace=flux-system \
    --from-file=age.agekey=/dev/stdin
