locals {
  account_id = "2bcc2c0c19d1ad6037c19ed8fe4a0043"
  zone_id    = "da22c5c98b60f20eb6854c15af389d6c"
  domain     = "home.hovirix.dev"

  apps = {
    authentik = {
      name     = "Authentik"
      hostname = "authentik.${local.domain}"
      upstream = "http://identity_authentik-server:9000"
    }

    cloudflare = {
      name = "Cloudflare"
      redirect_uris = [
        "https://hovirix.cloudflareaccess.com/cdn-cgi/access/callback",
      ]
    }

    grafana = {
      name     = "Grafana"
      hostname = "grafana.${local.domain}"
      upstream = "http://observability_grafana:3000"
      redirect_uris = [
        "https://grafana.${local.domain}/login/generic_oauth",
      ]
      logout_method = "frontchannel"
      logout_uri    = "https://grafana.${local.domain}/logout"
    }

    immich = {
      name     = "Immich"
      hostname = "immich.${local.domain}"
      upstream = "http://prod-apps-01.home.hovirix.dev:2283"
      redirect_uris = [
        "app.immich:///oauth-callback",
        "https://immich.${local.domain}/auth/login",
        "https://immich.${local.domain}/user-settings",
      ]
    }

    paperless = {
      name     = "Paperless"
      hostname = "paperless.${local.domain}"
      upstream = "http://prod-apps-01.home.hovirix.dev:8000"
      redirect_uris = [
        "https://paperless.${local.domain}/accounts/oidc/authentik/login/callback/",
      ]
    }

    vaultwarden = {
      name     = "Vaultwarden"
      hostname = "vaultwarden.${local.domain}"
      upstream = "http://applications_vaultwarden:80"
      redirect_uris = [
        "https://vaultwarden.${local.domain}/identity/connect/oidc-signin",
      ]
    }
  }
}
