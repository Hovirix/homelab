locals {
  account_id = "2bcc2c0c19d1ad6037c19ed8fe4a0043"
  zone_id    = "da22c5c98b60f20eb6854c15af389d6c"
  domain     = "home.hovirix.dev"

  apps = {
    grafana = {
      name     = "Grafana"
      hostname = "grafana.${local.domain}"

      redirect_uris = [
        "https://grafana.${local.domain}/login/generic_oauth",
      ]

      logout_method = "frontchannel"
      logout_uri    = "https://grafana.${local.domain}/logout"
    }

    immich = {
      name     = "Immich"
      hostname = "immich.${local.domain}"

      redirect_uris = [
        "app.immich:///oauth-callback",
        "https://immich.${local.domain}/auth/login",
        "https://immich.${local.domain}/user-settings",
      ]
    }

    paperless = {
      name     = "Paperless"
      hostname = "paperless.${local.domain}"

      redirect_uris = [
        "https://paperless.${local.domain}/accounts/oidc/authentik/login/callback/",
      ]
    }

    vaultwarden = {
      name     = "Vaultwarden"
      hostname = "vaultwarden.${local.domain}"

      redirect_uris = [
        "https://vaultwarden.${local.domain}/identity/connect/oidc-signin",
      ]

      access_token_validity = "minutes=10"
      offline_access        = true
      signed_tokens         = true
    }
  }

}
