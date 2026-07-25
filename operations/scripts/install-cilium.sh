#!/usr/bin/env bash
set -euo pipefail

version="$(yq e -r '.spec.chart.spec.version' ./platform/networking/cilium/release.yaml)"
values_file="./platform/networking/cilium/values.yaml"

helm upgrade --install cilium oci://quay.io/cilium/charts/cilium \
  --version "$version" \
  --namespace kube-system \
  --values "$values_file"
