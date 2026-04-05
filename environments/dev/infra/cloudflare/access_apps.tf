module "access_apps" {
  for_each = local.exposed_apps

  source = "../../../../platform/provisioning/cloudflare/modules/zt_access_application"

  account_id = local.account_id

  name     = each.key
  hostname = each.value.hostname

  allowed_idps = [module.authentik_idp.id]
  policy_ids   = local.access_policy_ids[each.value.access]
}
