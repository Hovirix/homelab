data "sops_file" "cloudflare" {
  source_file = "${path.module}/../../secrets/infrastructure/cloudflare.sops.yaml"
}

data "sops_file" "cloudflared" {
  source_file = "${path.module}/../../secrets/workloads/cloudflared.sops.yaml"
}
