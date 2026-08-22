resource "cloudflare_dns_record" "wildcard" {
  zone_id = local.zone_id
  name    = "*"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.homelab.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "homelab" {
  account_id = local.account_id
  name       = "homelab"
  config_src = "cloudflare"
  # tunnel_secret = "" # Must be at least 32 bytes and encoded as a base64 string.
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "homelab" {
  account_id = local.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.homelab.id

  config = {
    ingress = [
      {
        hostname = "*.${local.domain}"
        service  = "https://traefik.${local.domain}"
      },
      {
        service = "http_status:404"
      },
    ]
  }
}
