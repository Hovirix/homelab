# Cluster Bootstrap

Use this order for a fresh Kubernetes bootstrap on Talos.

## Source Paths

- `operations/taskfiles/cluster.yml`
- `docs/platform/gitops/index.md`
- `docs/platform/networking/cni.md`
- `docs/operations/runbooks/sops-age-flux.md`

## Order

1. Run `task tofu:apply stack=talos`.
2. Store the Flux Age private key in `secrets/infrastructure.sops.yaml` at `flux.sops_age_key`.
3. Run `task cluster:bootstrap`.

## Notes

- `cluster:bootstrap` generates Talos configs, installs Cilium, bootstraps Flux, and applies the SOPS Age key.
- The Cilium version is read from `platform/networking/cni/release.yaml`.
- Flux takes over `platform/` after the controllers are running.
- Flux decrypts SOPS files in-cluster using the `sops-age` Secret referenced by the `platform` Flux `Kustomization`.
- The private Age key stays encrypted in `secrets/platform.sops.yaml` and is piped directly into the cluster Secret during bootstrap.
