data "sops_file" "identity" {
  source_file = "${path.module}/../../../../../secrets/identity.sops.yaml"
}
