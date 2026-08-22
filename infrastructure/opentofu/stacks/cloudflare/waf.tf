resource "cloudflare_ruleset" "homelab_country" {
  zone_id     = local.zone_id
  name        = "Homelab country restriction"
  description = "Block non-Italian traffic to the homelab subdomain."
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules = [
    {
      action      = "block"
      description = "Block non-Italian homelab traffic"
      expression  = "(http.host wildcard \"*.home.hovirix.dev\" and ip.src.country ne \"IT\")"
      ref         = "block_non_italian_homelab_traffic"
    },
  ]
}
