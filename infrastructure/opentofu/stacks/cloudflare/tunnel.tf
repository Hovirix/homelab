resource "cloudflare_dns_record" "apps" {
  for_each = local.hostnames

  zone_id = local.zone_id
  name    = each.key
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.homelab.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "homelab" {
  account_id = local.account_id
  name       = "homelab"
  config_src = "cloudflare"

  # The provider retains this optional field even though it is not configured.
  lifecycle {
    ignore_changes = [tunnel_secret]
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "homelab" {
  account_id = local.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.homelab.id

  config = {
    ingress = concat([
      for hostname in local.hostnames : {
        hostname = hostname
        service  = "https://traefik_proxy:443"
        origin_request = {
          origin_server_name = local.domain
        }
      }
      ], [
      {
        service = "http_status:404"
      },
    ])
  }
}
