data "sops_file" "infrastructure" {
  source_file = "${path.module}/../../../../secrets/infrastructure.sops.yaml"
}

data "http" "fcos_stable" {
  url = "https://builds.coreos.fedoraproject.org/streams/stable.json"
}
