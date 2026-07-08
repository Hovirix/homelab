data "sops_file" "infrastructure" {
  source_file = "${path.module}/../../../../secrets/infrastructure.sops.yaml"
}
