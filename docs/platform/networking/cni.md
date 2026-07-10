# CNI

Use this page to deploy the current Kubernetes CNI on Talos.

## Source Paths

- `platform/networking/cni/kustomization.yaml`
- `platform/networking/cni/source.yaml`
- `platform/networking/cni/release.yaml`
- `platform/networking/cni/values.yaml`
- `infrastructure/opentofu/stacks/prod/talos/patches/controlplane.yaml`
- `infrastructure/opentofu/stacks/prod/talos/locals.tf`

## Current State

- The Talos machine config already sets `cluster.network.cni.name: none`.
- The Talos patch disables kube-proxy.
- The cluster is therefore ready for a Flux-managed Cilium install with kube-proxy replacement enabled.

## Reconcile

Reconcile the Flux Kustomization that points at this directory after Flux itself is bootstrapped:

```bash
flux reconcile kustomization platform --with-source
```

## Deploy

```bash
task cluster:bootstrap
```

## Notes

- OCI registries are the recommended install path.
- The bootstrap task reads the chart version from `platform/networking/cni/release.yaml`.
- Keep `kubeProxyReplacement: true` with `k8sServiceHost=localhost` and `k8sServicePort=7445` while Talos disables kube-proxy.
- Talos already provides `cgroupv2` and `bpffs`, so the chart must not try to mount them.
- Do not add `SYS_MODULE` to the capability set.
