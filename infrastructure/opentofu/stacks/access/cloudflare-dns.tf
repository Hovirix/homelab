resource "cloudflare_dns_record" "app" {
  for_each = local.cloudflare_apps

  zone_id = local.zone_id
  name    = each.key
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.homelab.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}
