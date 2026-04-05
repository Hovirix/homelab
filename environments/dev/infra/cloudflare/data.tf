data "sops_file" "cloudflare" {
  source_file = "${path.module}/../../../../security/secrets/infrastructure/cloudflare.sops.yaml"
}

data "sops_file" "authentik_clients" {
  source_file = "${path.module}/../../../../security/secrets/identity/oauth-clients.sops.yaml"
}
