data "sops_file" "cloudflare" {
  source_file = "${path.module}/../../security/secrets/infrastructure/cloudflare.sops.yaml"
}

data "sops_file" "cloudflared" {
  source_file = "${path.module}/../../security/secrets/services/cloudflared.sops.yaml"
}
