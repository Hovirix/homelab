data "sops_file" "infrastructure" {
  source_file = "${path.module}/../../../../secrets/infrastructure.sops.yaml"
}

data "sops_file" "identity" {
  source_file = "${path.module}/../../../../secrets/identity.sops.yaml"
}
