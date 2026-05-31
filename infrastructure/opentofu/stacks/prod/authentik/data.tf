data "sops_file" "authentik_token" {
  source_file = "${path.module}/../../../../../secrets/infrastructure/authentik.sops.yaml"
}

data "sops_file" "authentik_clients" {
  source_file = "${path.module}/../../../../../secrets/identity/oauth-clients.sops.yaml"
}
