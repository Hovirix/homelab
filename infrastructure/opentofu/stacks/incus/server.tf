variable "incus_acme_token" {
  description = "Cloudflare DNS token shared with the Proxmox ACME configuration."
  type        = string
  sensitive   = true
}

resource "incus_server" "acme" {
  config = {
    "acme.agree_tos"            = "true"
    "acme.ca_url"               = "https://acme-v02.api.letsencrypt.org/directory"
    "acme.domain"               = "incus.home.hovirix.dev"
    "acme.email"                = "homelab@hovirix.dev"
    "acme.challenge"            = "DNS-01"
    "acme.provider"             = "cloudflare"
    "acme.provider.environment" = "CF_DNS_API_TOKEN=${var.incus_acme_token}"
    "acme.provider.resolvers"   = "1.1.1.1:53,1.0.0.1:53"
  }
}
