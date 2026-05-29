locals {
  application_hostnames = {
    for name in keys(var.applications) : name => "${name}.${var.domain}"
  }

  invalid_application_policies = [
    for name, app in var.applications : "${name}:${app.access_policy}"
    if !contains(keys(var.access_policies), app.access_policy)
  ]

  tunnel_ingress = concat(
    [
      for name, app in var.applications : {
        hostname = local.application_hostnames[name]
        service  = app.upstream
      }
    ],
    [
      {
        service = "http_status:404"
      }
    ]
  )

  access_policy_ids = {
    for name in keys(var.access_policies) : name => concat(
      [module.access_policy_allow[name].id],
      contains(keys(module.access_policy_country_restriction), name) ? [module.access_policy_country_restriction[name].id] : []
    )
  }
}

resource "terraform_data" "validate" {
  input = true

  lifecycle {
    precondition {
      condition     = length(local.invalid_application_policies) == 0
      error_message = "Applications reference undefined access policies: ${join(", ", local.invalid_application_policies)}."
    }
  }
}

module "identity_provider" {
  source = "../zero_trust_access_identity_provider"

  account_id = var.account_id
  name       = var.identity_provider.name

  client_id     = var.identity_provider.client_id
  client_secret = var.identity_provider.client_secret

  auth_url  = var.identity_provider.auth_url
  token_url = var.identity_provider.token_url
  certs_url = var.identity_provider.certs_url

  scopes       = var.identity_provider.scopes
  claims       = var.identity_provider.claims
  pkce_enabled = var.identity_provider.pkce_enabled
}

module "access_policy_allow" {
  for_each = var.access_policies

  source = "../zero_trust_access_policy"

  account_id = var.account_id
  name       = "${var.identity_provider.name}-${each.key}"
  decision   = "allow"

  include = [
    {
      login_method = {
        id = module.identity_provider.id
      }
    }
  ]

  require = [
    {
      oidc = {
        claim_name           = "groups"
        claim_value          = each.value.group
        identity_provider_id = module.identity_provider.id
      }
    }
  ]

  exclude = []
}

module "access_policy_country_restriction" {
  for_each = {
    for name, policy in var.access_policies : name => policy
    if length(policy.allowed_countries) > 0
  }

  source = "../zero_trust_access_policy"

  account_id = var.account_id
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

module "tunnel" {
  source = "../zero_trust_tunnel_cloudflared"

  account_id = var.account_id
  name       = var.tunnel.name
  config_src = var.tunnel.config_src
  ingress    = local.tunnel_ingress
}

module "applications" {
  for_each = var.applications

  source = "../zero_trust_exposed_application"

  depends_on = [terraform_data.validate]

  account_id = var.account_id
  zone_id    = var.zone_id

  name         = each.key
  dns_name     = each.key
  hostname     = local.application_hostnames[each.key]
  service      = each.value.upstream
  tunnel_cname = module.tunnel.cname

  allowed_idps     = [module.identity_provider.id]
  policy_ids       = local.access_policy_ids[each.value.access_policy]
  session_duration = each.value.session_duration
}
