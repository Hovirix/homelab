module "access_application" {
  source = "../zt_access_application"

  account_id = var.account_id

  name             = var.name
  hostname         = var.hostname
  type             = var.type
  allowed_idps     = var.allowed_idps
  session_duration = var.session_duration
  policy_ids       = var.policy_ids
}

resource "cloudflare_dns_record" "this" {
  zone_id = var.zone_id
  name    = coalesce(var.dns_name, var.name)
  type    = "CNAME"
  content = var.tunnel_cname
  proxied = true
  ttl     = 1
}
