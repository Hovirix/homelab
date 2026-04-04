resource "cloudflare_zero_trust_tunnel_cloudflared" "homelab" {
  account_id = local.account_id
  name       = "homelab"
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "homelab" {
  account_id = local.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.homelab.id

  config = {
    ingress = [
      {
        hostname = "authentik.${local.domain}"
        service  = "http://prod-idp-01.home.hovirix.dev:9000"
      },
      {
        hostname = "immich.${local.domain}"
        service  = "http://prod-apps-01.home.hovirix.dev:2283"
      },
      {
        hostname = "paperless.${local.domain}"
        service  = "http://prod-apps-01.home.hovirix.dev:8000"
      },
      {
        hostname = "vaultwarden.${local.domain}"
        service  = "http://prod-apps-01.home.hovirix.dev:80"
      },
      {
        hostname = "grafana.${local.domain}"
        service  = "http://prod-monitoring-01.home.hovirix.dev:3000"
      },
      {
        service = "http_status:404"
      }
    ]
  }
}
