# Cluster Bootstrap

Use this order for a fresh Kubernetes bootstrap on Talos.

## Source Paths

- `operations/taskfiles/talos.yml`
- `operations/taskfiles/flux.yml`
- `operations/taskfiles/cluster.yml`
- `docs/platform/gitops/index.md`
- `docs/platform/networking/cni.md`
- `docs/operations/runbooks/sops-age-flux.md`

## Order

1. Run `task tofu:apply stack=talos`.
2. Store the Flux Age private key in `secrets/infrastructure.sops.yaml` at `flux.sops_age_key`.
3. Run `task cluster:bootstrap`.

## Notes

- `talos:bootstrap` installs the CNI from the version declared in `platform/networking/cni/release.yaml`.
- `flux:bootstrap` applies Flux controllers first, creates or updates the `sops-age` Secret, and then applies the Flux sync object.
- Flux can take over `platform/` after the controllers are running.
- Flux decrypts SOPS files in-cluster using the `sops-age` Secret referenced by the `platform` Flux `Kustomization`.
- The private Age key stays encrypted in `secrets/infrastructure.sops.yaml` and is piped directly into the cluster Secret during bootstrap.
