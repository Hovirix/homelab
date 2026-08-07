resource "terraform_data" "validate_cloudflare_apps" {
  input = true

  lifecycle {
    precondition {
      condition     = length(local.invalid_cloudflare_application_policies) == 0
      error_message = "Applications reference undefined access policies: ${join(", ", local.invalid_cloudflare_application_policies)}."
    }
  }
}

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
    claims = ["groups"]

    pkce_enabled = true
  }
}

resource "cloudflare_zero_trust_access_policy" "allow" {
  for_each = local.access_policies

  account_id = local.account_id
  name       = "authentik-${each.key}"
  decision   = "allow"

  include = [
    {
      login_method = {
        id = cloudflare_zero_trust_access_identity_provider.authentik.id
      }
    }
  ]

  require = [
    {
      oidc = {
        claim_name           = "groups"
        claim_value          = each.value.group
        identity_provider_id = cloudflare_zero_trust_access_identity_provider.authentik.id
      }
    }
  ]

  exclude = []
}

resource "cloudflare_zero_trust_access_policy" "country_restriction" {
  for_each = {
    for name, policy in local.access_policies : name => policy
    if length(policy.allowed_countries) > 0
  }

  account_id = local.account_id
  name       = "block-${each.key}-outside-${lower(join("-", each.value.allowed_countries))}"
  decision   = "deny"

  include = [
    {
      everyone = {}
    }
  ]

  require = []

  exclude = [
    for country in each.value.allowed_countries : {
      geo = {
        country_code = country
      }
    }
  ]
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "homelab" {
  account_id = local.account_id
  name       = local.tunnel.name
  config_src = local.tunnel.config_src
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "homelab" {
  account_id = local.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.homelab.id

  config = {
    ingress = local.cloudflare_tunnel_ingress
  }
}

resource "cloudflare_zero_trust_access_application" "app" {
  for_each = local.cloudflare_apps

  depends_on = [terraform_data.validate_cloudflare_apps]

  account_id = local.account_id

  name             = each.value.name
  type             = "self_hosted"
  session_duration = try(each.value.cloudflare.session_duration, "24h")
  allowed_idps     = [cloudflare_zero_trust_access_identity_provider.authentik.id]

  destinations = [
    {
      type = "public"
      uri  = local.cloudflare_application_hostnames[each.key]
    }
  ]

  policies = [
    for id in local.cloudflare_access_policy_ids[each.value.cloudflare.access_policy] : {
      id = id
    }
  ]
}

resource "cloudflare_dns_record" "app" {
  for_each = local.cloudflare_apps

  zone_id = local.zone_id
  name    = each.key
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.homelab.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}
