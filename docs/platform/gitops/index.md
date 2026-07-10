# GitOps

Use this directory for the GitOps bootstrap manifests.

## Source Paths

- `platform/gitops/kustomization.yaml`
- `platform/gitops/gotk-components.yaml`
- `platform/gitops/gotk-sync.yaml`

## Current State

- The manifests are committed under `platform/gitops/`.
- The sync object points at `./platform` in the `homelab` repository on `main`.
- The platform root includes `gitops/` so Flux can reconcile itself after bootstrap.
- The `platform` Flux `Kustomization` uses SOPS decryption with the `sops-age` Secret in `flux-system`.

## Apply

```bash
kubectl apply -k platform/gitops
```

## Notes

- This directory seeds Flux and then remains part of the steady-state platform tree.
- Install the `sops-age` Secret before reconciling encrypted `*.sops.yaml` manifests.
