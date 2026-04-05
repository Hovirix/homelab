resource "cloudflare_dns_record" "authentik" {
  zone_id = local.zone_id
  name    = "authentik"
  type    = "CNAME"
  content = "${module.homelab_tunnel.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "grafana" {
  zone_id = local.zone_id
  name    = "grafana"
  type    = "CNAME"
  content = "${module.homelab_tunnel.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "immich" {
  zone_id = local.zone_id
  name    = "immich"
  type    = "CNAME"
  content = "${module.homelab_tunnel.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "paperless" {
  zone_id = local.zone_id
  name    = "paperless"
  type    = "CNAME"
  content = "${module.homelab_tunnel.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "vaultwarden" {
  zone_id = local.zone_id
  name    = "vaultwarden"
  type    = "CNAME"
  content = "${module.homelab_tunnel.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}
