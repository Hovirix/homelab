resource "cloudflare_zero_trust_access_identity_provider" "authentik" {
  account_id = local.account_id
  name       = "authentik"
  type       = "oidc"

  config = {
    client_id     = data.sops_file.identity.data["oauth.cloudflare.client_id"]
    client_secret = data.sops_file.identity.data["oauth.cloudflare.client_secret"]

    auth_url  = "https://authentik.${local.domain}/application/o/authorize/"
    token_url = "https://authentik.${local.domain}/application/o/token/"
    certs_url = "https://authentik.${local.domain}/application/o/cloudflare/jwks/"

    scopes = ["openid", "profile", "email"]
  }
}

resource "cloudflare_zero_trust_access_policy" "authentik" {
  account_id = local.account_id
  name       = "authentik-authenticated"
  decision   = "allow"

  include = [
    {
      login_method = {
        id = cloudflare_zero_trust_access_identity_provider.authentik.id
      }
    }
  ]
}

resource "cloudflare_zero_trust_access_policy" "deny_outside_fr" {
  account_id = local.account_id
  name       = "block-authenticated-outside-fr"
  decision   = "deny"

  include = [
    {
      everyone = {}
    }
  ]

  exclude = [
    {
      geo = {
        country_code = "FR"
      }
    }
  ]
}

resource "cloudflare_zero_trust_access_application" "app" {
  for_each = local.apps

  account_id = local.account_id

  name         = each.value.name
  type         = "self_hosted"
  allowed_idps = [cloudflare_zero_trust_access_identity_provider.authentik.id]

  destinations = [
    {
      type = "public"
      uri  = each.value.hostname
    }
  ]

  policies = [
    {
      id = cloudflare_zero_trust_access_policy.authentik.id
    },
    {
      id = cloudflare_zero_trust_access_policy.deny_outside_fr.id
    },
  ]
}
