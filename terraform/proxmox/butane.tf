locals {
  butane_prod_db_01 = templatefile(
    "${path.module}/../../hosts/prod-db-01.tftpl",
    {
      postgres_password             = data.sops_file.postgres.data["postgres.password"]
      postgres_immich_password      = data.sops_file.postgres.data["postgres.immich_password"]
      postgres_grafana_password     = data.sops_file.postgres.data["postgres.grafana_password"]
      postgres_paperless_password   = data.sops_file.postgres.data["postgres.paperless_password"]
      postgres_authentik_password   = data.sops_file.postgres.data["postgres.authentik_password"]
      postgres_vaultwarden_password = data.sops_file.postgres.data["postgres.vaultwarden_password"]
    }
  )
  butane_prod_idp_01 = templatefile(
    "${path.module}/../../hosts/prod-idp-01.tftpl",
    {
      authentik_secret_key         = data.sops_file.authentik.data["authentik.secret_key"]
      authentik_bootstrap_email    = data.sops_file.authentik.data["authentik.bootstrap_email"]
      authentik_bootstrap_token    = data.sops_file.authentik.data["authentik.bootstrap_token"]
      authentik_bootstrap_password = data.sops_file.authentik.data["authentik.bootstrap_password"]
      postgres_authentik_password  = data.sops_file.postgres.data["postgres.authentik_password"]
    }
  )
  butane_prod_app_01 = templatefile(
    "${path.module}/../../hosts/prod-app-01.tftpl",
    {
      postgres_immich_password      = data.sops_file.postgres.data["postgres.immich_password"]
      postgres_paperless_password   = data.sops_file.postgres.data["postgres.paperless_password"]
      postgres_vaultwarden_password = data.sops_file.postgres.data["postgres.vaultwarden_password"]
      paperless_secret_key          = data.sops_file.paperless.data["paperless_secret_key"]
      paperless_client_id           = data.sops_file.oauth_clients.data["oauth.paperless.client_id"]
      paperless_client_secret       = data.sops_file.oauth_clients.data["oauth.paperless.client_secret"]
      installation_id               = data.sops_file.vaultwarden.data["installation_id"]
      installation_key              = data.sops_file.vaultwarden.data["installation_key"]
    }
  )
  butane_prod_proxy_01 = templatefile(
    "${path.module}/../../hosts/prod-proxy-01.tftpl",
    {
      caddy_cloudflare_dns_token = data.sops_file.caddy.data["caddy_cloudflare_dns_token"]
    }
  )
}
