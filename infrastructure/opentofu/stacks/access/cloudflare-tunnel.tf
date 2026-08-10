resource "cloudflare_zero_trust_tunnel_cloudflared" "homelab" {
  account_id = local.account_id
  name       = "homelab"
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "homelab" {
  account_id = local.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.homelab.id

  config = {
    ingress = concat(
      [
        for slug, app in local.apps : {
          hostname = app.hostname
          service  = "https://${app.hostname}"
        }
      ],
      [
        {
          service = "http_status:404"
        }
      ]
    )
  }
}
