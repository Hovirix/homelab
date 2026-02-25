data "sops_file" "postgres" {
  source_file = "${path.module}/../../secrets/prod-db-01/postgres.yaml"
}

data "sops_file" "authentik" {
  source_file = "${path.module}/../../secrets/prod-idp-01/authentik.yaml"
}

data "sops_file" "paperless" {
  source_file = "${path.module}/../../secrets/prod-app-01/paperless.yaml"
}

data "sops_file" "vaultwarden" {
  source_file = "${path.module}/../../secrets/prod-app-01/vaultwarden.yaml"
}

data "sops_file" "oauth_clients" {
  source_file = "${path.module}/../../secrets/prod-idp-01/oauth-clients.yaml"
}

