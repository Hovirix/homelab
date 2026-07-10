#!/usr/bin/env bash
set -euo pipefail

version="$(yq e -r '.spec.chart.spec.version' ./platform/networking/cni/release.yaml)"

helm install cilium oci://quay.io/cilium/charts/cilium \
  --version "$version" \
  --namespace kube-system
