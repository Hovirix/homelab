locals {
  access_policies = {
    authenticated = {
      allowed_countries = ["FR"]
    }
  }

  cloudflare_access_policy = "authenticated"

  cloudflare_apps = {
    for slug, app in local.apps : slug => app
    if can(app.hostname) && can(app.upstream)
  }

  invalid_cloudflare_application_policies = contains(keys(local.access_policies), local.cloudflare_access_policy) ? [] : [local.cloudflare_access_policy]

  cloudflare_access_policy_ids = concat(
    [cloudflare_zero_trust_access_policy.allow[local.cloudflare_access_policy].id],
    contains(keys(cloudflare_zero_trust_access_policy.country_restriction), local.cloudflare_access_policy) ? [cloudflare_zero_trust_access_policy.country_restriction[local.cloudflare_access_policy].id] : []
  )
}

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

  exclude = [
    for country in each.value.allowed_countries : {
      geo = {
        country_code = country
      }
    }
  ]
}

resource "cloudflare_zero_trust_access_application" "app" {
  for_each = local.cloudflare_apps

  depends_on = [terraform_data.validate_cloudflare_apps]

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
    for id in local.cloudflare_access_policy_ids : {
      id = id
    }
  ]
}
