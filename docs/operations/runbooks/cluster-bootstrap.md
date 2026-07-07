# Cluster Bootstrap

Use this order for a fresh Kubernetes bootstrap on Talos.

## Source Paths

- `operations/taskfiles/talos.yml`
- `operations/taskfiles/flux.yml`
- `operations/taskfiles/cluster.yml`
- `docs/platform/gitops/index.md`
- `docs/platform/networking/cni.md`

## Order

1. Run `task tofu:apply stack=talos`.
2. Run `task talos:bootstrap`.
3. Run `task flux:bootstrap`.
4. Run `task cluster:bootstrap` if you want both steps in one command.

## Notes

- `talos:bootstrap` installs the CNI from the version declared in `platform/networking/cni/release.yaml`.
- `flux:bootstrap` applies the Flux bootstrap manifests from `platform/gitops/`.
- Flux can take over `platform/` after the controllers are running.
