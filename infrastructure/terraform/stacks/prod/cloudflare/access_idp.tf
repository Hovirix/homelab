module "authentik_idp" {
  source = "../../../modules/cloudflare/zt_access_identidy_provider"

  account_id = local.account_id
  name       = "authentik"

  client_id     = data.sops_file.authentik_clients.data["oauth.cloudflare.client_id"]
  client_secret = data.sops_file.authentik_clients.data["oauth.cloudflare.client_secret"]

  auth_url  = "https://authentik.${local.domain}/application/o/authorize/"
  token_url = "https://authentik.${local.domain}/application/o/token/"
  certs_url = "https://authentik.${local.domain}/application/o/cloudflare/jwks/"

  scopes = [
    "openid",
    "profile",
    "email",
  ]

  claims = [
    "groups",
  ]

  pkce_enabled = true
}
