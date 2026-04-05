module "policy_authentik_admins" {
  source = "../../../../platform/provisioning/cloudflare/modules/zt_access_policy"

  account_id = local.account_id
  name       = "authentik-admins"
  decision   = "allow"

  include = [
    {
      login_method = {
        id = module.authentik_idp.id
      }
    }
  ]

  require = [
    {
      oidc = {
        claim_name           = "groups"
        claim_value          = "admins"
        identity_provider_id = module.authentik_idp.id
      }
    }
  ]

  exclude = []
}

module "policy_authentik_users" {
  source = "../../../../platform/provisioning/cloudflare/modules/zt_access_policy"

  account_id = local.account_id
  name       = "authentik-users"
  decision   = "allow"

  include = [
    {
      login_method = {
        id = module.authentik_idp.id
      }
    }
  ]

  require = [
    {
      oidc = {
        claim_name           = "groups"
        claim_value          = "users"
        identity_provider_id = module.authentik_idp.id
      }
    }
  ]

  exclude = []
}

module "policy_block_non_fr" {
  source = "../../../../platform/provisioning/cloudflare/modules/zt_access_policy"

  account_id = local.account_id
  name       = "block-non-fr"
  decision   = "deny"

  include = [
    {
      everyone = {}
    }
  ]

  require = []

  exclude = [
    {
      geo = {
        country_code = "FR"
      }
    }
  ]
}
