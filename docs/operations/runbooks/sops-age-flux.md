# Flux SOPS Age Decryption

Use this runbook to manage in-cluster SOPS decryption for Flux with Age.

## Source Paths

- `.sops.yaml`
- `platform/gitops/gotk-sync.yaml`
- `platform/networking/certificates/kustomization.yaml`
- `platform/networking/certificates/cloudflare-token-secret.sops.yaml`

## References

- Flux SOPS guide: <https://fluxcd.io/flux/guides/mozilla-sops/>
- Flux Kustomization decryption API: <https://fluxcd.io/flux/components/kustomize/kustomizations/#decryption>
- SOPS Age documentation: <https://getsops.io/docs/#encrypting-using-age>

## Required Flux Kustomization

The `platform` Flux `Kustomization` in `platform/gitops/gotk-sync.yaml` must configure SOPS decryption because it reconciles `./platform`, including encrypted Kubernetes Secret manifests under the platform tree.

The local `kustomization.yaml` files do not configure decryption. They only list resources for Kustomize to build. Flux performs SOPS decryption from the Flux `Kustomization` object before applying resources to the cluster.

## Generate Age Keys

Generate an Age key pair on an operator workstation:

```bash
age-keygen -o age.agekey
```

The command prints the public recipient to stdout. The recipient starts with `age1` and is safe to commit in `.sops.yaml`.

Keep `age.agekey` private. Do not commit it to Git.

## Install the Private Key in Flux

The bootstrap tasks expect the private key in `secrets/platform.sops.yaml` at `flux.sops_age_key`:

```yaml
flux:
  sops_age_key: |
    # created: 2026-07-10T00:00:00Z
    # public key: age1...
    AGE-SECRET-KEY-...
```

Create the decryption Secret in the `flux-system` namespace manually if needed:

```bash
cat age.agekey |
  kubectl create secret generic sops-age \
    --namespace=flux-system \
    --from-file=age.agekey=/dev/stdin
```

The file key must end with `.agekey` so Flux can detect it as an Age key.

Verify the Secret exists without printing the private key:

```bash
kubectl -n flux-system get secret sops-age
```

The cluster bootstrap task performs this step automatically by decrypting `flux.sops_age_key` locally and piping it into Kubernetes:

```bash
task cluster:bootstrap
```

Use a non-default encrypted file or field when needed:

```bash
task cluster:bootstrap \
  sops_file=secrets/platform.sops.yaml \
  sops_age_key_path='["flux"]["sops_age_key"]'
```

## Encrypt a cert-manager Cloudflare Token

Create the plaintext manifest locally at `platform/networking/certificates/cloudflare-token-secret.sops.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token-secret
  namespace: cert-manager
type: Opaque
stringData:
  api-token: REPLACE_WITH_CLOUDFLARE_API_TOKEN
```

Encrypt it with SOPS and Age:

```bash
sops --encrypt --in-place platform/networking/certificates/cloudflare-token-secret.sops.yaml
```

The repository `.sops.yaml` selects the Age recipient and encrypts only `data` and `stringData`, which follows Flux guidance for Kubernetes Secrets.

Add the encrypted Secret to `platform/networking/certificates/kustomization.yaml` exactly like any other resource:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yaml
  - source.yaml
  - release.yaml
  - cloudflare-token-secret.sops.yaml
  - cluster-issuer.yaml
  - wildcard-certificate.yaml

configMapGenerator:
  - name: cert-manager-values
    namespace: flux-system
    files:
      - values.yaml

generatorOptions:
  disableNameSuffixHash: true
```

Do not also include a plaintext Secret for the same `metadata.name` and `metadata.namespace`.

## Expected Reconciliation Flow

1. `source-controller` fetches the Git revision for the `homelab` `GitRepository`.
2. `kustomize-controller` reconciles the `platform` Flux `Kustomization`.
3. `kustomize-controller` reads the `sops-age` Secret from `flux-system`.
4. `kustomize-controller` decrypts matching SOPS files during reconciliation.
5. `kustomize-controller` builds `./platform` with Kustomize.
6. `kustomize-controller` applies the decrypted Secret to `cert-manager`.
7. cert-manager reads `cloudflare-api-token-secret` when solving DNS01 challenges.

## Rotate the Age Key

Generate a replacement key:

```bash
age-keygen -o age-new.agekey
```

Update `.sops.yaml` with the new public recipient.

Re-encrypt each encrypted manifest with the new recipient:

```bash
sops updatekeys platform/networking/certificates/cloudflare-token-secret.sops.yaml
```

Replace the cluster Secret after committing the re-encrypted manifests:

```bash
kubectl -n flux-system delete secret sops-age

cat age-new.agekey |
  kubectl create secret generic sops-age \
    --namespace=flux-system \
    --from-file=age.agekey=/dev/stdin
```

Reconcile Flux:

```bash
flux reconcile source git homelab -n flux-system
flux reconcile kustomization platform -n flux-system --with-source
```

Keep the previous private key until Flux has successfully reconciled all re-encrypted files.

## Verify Decryption

Validate the local Kustomize build:

```bash
kustomize build platform
```

Ask the Kubernetes API server to validate the built manifests:

```bash
kustomize build platform | kubectl apply --dry-run=server -f -
```

Check Flux health:

```bash
flux check
flux get kustomizations -n flux-system
flux get kustomization platform -n flux-system
```

Force reconciliation when needed:

```bash
flux reconcile kustomization platform -n flux-system --with-source
```

Verify the decrypted Secret exists without printing its data:

```bash
kubectl -n cert-manager get secret cloudflare-api-token-secret
```

## Troubleshooting

If Flux reports SOPS decryption errors, verify `sops-age` exists in `flux-system` and contains a file key ending in `.agekey`.

If Flux reports no matching Age identities, verify the private key in `sops-age` matches the public recipient in `.sops.yaml` and the encrypted file metadata.

If Kustomize reports duplicate resources, remove either the plaintext Secret or the encrypted Secret from the local `kustomization.yaml`; keep only the encrypted manifest.

If cert-manager reports the Cloudflare token Secret is missing, verify the encrypted Secret manifest is included in `platform/networking/certificates/kustomization.yaml` and the `platform` Flux `Kustomization` is Ready.

If local `kustomize build` shows encrypted values, that is expected. Flux decrypts in-cluster during `kustomize-controller` reconciliation, not during a local Kustomize build.
