data "sops_file" "infrastructure" {
  source_file = "${path.module}/../../../../secrets/infrastructure.sops.yaml"
}

data "sops_file" "platform" {
  source_file = "${path.module}/../../../../secrets/platform.sops.yaml"
}
