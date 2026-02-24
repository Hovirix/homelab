data "sops_file" "authentik_token" {
  source_file = "../../secrets/terraform/authentik.yaml"
}

data "sops_file" "authentik_clients" {
  source_file = "../../secrets/prod-idp-01/oauth-clients.yaml"
}
