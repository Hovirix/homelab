module "cloudflare" {
  source = "../../../modules/authentik/oauth2_application"

  name = "Cloudflare"
  slug = "cloudflare"

  client_id     = data.sops_file.authentik_clients.data["oauth.cloudflare.client_id"]
  client_secret = data.sops_file.authentik_clients.data["oauth.cloudflare.client_secret"]

  redirect_uris = [
    "https://hovirix.cloudflareaccess.com/cdn-cgi/access/callback",
  ]
}

module "grafana" {
  source = "../../../modules/authentik/oauth2_application"

  name = "Grafana"
  slug = "grafana"

  client_id     = data.sops_file.authentik_clients.data["oauth.grafana.client_id"]
  client_secret = data.sops_file.authentik_clients.data["oauth.grafana.client_secret"]

  redirect_uris = [
    "https://grafana.home.hovirix.dev/login/generic_oauth",
  ]
}

module "immich" {
  source = "../../../modules/authentik/oauth2_application"

  name = "Immich"
  slug = "immich"

  client_id     = data.sops_file.authentik_clients.data["oauth.immich.client_id"]
  client_secret = data.sops_file.authentik_clients.data["oauth.immich.client_secret"]

  redirect_uris = [
    "app.immich:///oauth-callback",
    "https://immich.home.hovirix.dev/auth/login",
    "https://immich.home.hovirix.dev/user-settings",
  ]
}

module "paperless" {
  source = "../../../modules/authentik/oauth2_application"

  name = "Paperless"
  slug = "paperless"

  client_id     = data.sops_file.authentik_clients.data["oauth.paperless.client_id"]
  client_secret = data.sops_file.authentik_clients.data["oauth.paperless.client_secret"]

  redirect_uris = [
    "https://paperless.home.hovirix.dev/accounts/oidc/authentik/login/callback/",
  ]
}
