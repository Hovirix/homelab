resource "cloudflare_ruleset" "homelab_country" {
  zone_id     = local.zone_id
  name        = "Homelab country restriction"
  description = "Block non-Italian traffic to homelab apps."
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules = [
    {
      action      = "block"
      description = "Block non-Italian homelab traffic"
      expression  = "(http.host in {${join(" ", [for hostname in local.hostnames : jsonencode(hostname)])}} and ip.src.country ne \"IT\")"
      ref         = "block_non_italian_homelab_traffic"
    },
  ]
}
