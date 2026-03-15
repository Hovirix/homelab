data "sops_file" "caddy" {
  source_file = "${path.module}/../../secrets/workloads/caddy.yaml"
}

data "sops_file" "postgres" {
  source_file = "${path.module}/../../secrets/workloads/postgres.yaml"
}

data "sops_file" "authentik" {
  source_file = "${path.module}/../../secrets/workloads/authentik.yaml"
}

data "sops_file" "paperless" {
  source_file = "${path.module}/../../secrets/workloads/paperless.yaml"
}

data "sops_file" "vaultwarden" {
  source_file = "${path.module}/../../secrets/workloads/vaultwarden.yaml"
}

data "sops_file" "oauth_clients" {
  source_file = "${path.module}/../../secrets/identity/oauth-clients.yaml"
}

data "sops_file" "proxmox" {
  source_file = "${path.module}/../../secrets/infrastructure/proxmox.yaml"
}

