resource "cloudflare_zero_trust_access_identity_provider" "this" {
  account_id = var.account_id
  name       = var.name
  type       = "oidc"

  config = {
    client_id     = var.client_id
    client_secret = var.client_secret

    auth_url  = var.auth_url
    token_url = var.token_url
    certs_url = var.certs_url

    scopes = var.scopes
    claims = var.claims

    pkce_enabled = var.pkce_enabled
  }
}
