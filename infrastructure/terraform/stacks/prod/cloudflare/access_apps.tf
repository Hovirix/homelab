module "access_apps" {
  for_each = local.exposed_apps

  source = "../../../modules/cloudflare/exposed_app"

  account_id = local.account_id
  zone_id    = local.zone_id

  name         = each.key
  dns_name     = each.key
  hostname     = each.value.hostname
  service      = each.value.service
  tunnel_cname = module.homelab_tunnel.cname

  allowed_idps = [module.authentik_idp.id]
  policy_ids   = local.access_policy_ids[each.value.access]
}
