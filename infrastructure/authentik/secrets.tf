data "sops_file" "authentik_token" {
  source_file = "../../secrets/infrastructure/authentik.sops.yaml"
}

data "sops_file" "authentik_clients" {
  source_file = "../../secrets/identity/oauth-clients.sops.yaml"
}
