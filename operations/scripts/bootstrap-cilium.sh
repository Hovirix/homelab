#!/usr/bin/env bash
set -euo pipefail

namespace="${1:?namespace required}"
release="${2:?release required}"
chart="${3:?chart required}"
version="${4:?version required}"
values="${5:?values file required}"

existing_namespace="$(kubectl get ns "$namespace" -o jsonpath='{.metadata.name}' 2>/dev/null || true)"
if [ "$existing_namespace" = "" ]; then
  exit 1
fi

if helm status "$release" -n "$namespace" >/dev/null 2>&1; then
  exit 0
fi

kubectl -n "$namespace" get deploy "$release" >/dev/null 2>&1 && exit 0
kubectl -n "$namespace" get ds "$release" >/dev/null 2>&1 && exit 0

helm upgrade --install "$release" "$chart" \
  --version "$version" \
  --namespace "$namespace" \
  --create-namespace \
  --values "$values"
