resource "cloudflare_zone_dnssec" "main" {
  zone_id = local.zone_id
  status  = "active"
}

resource "cloudflare_zone_setting" "ssl" {
  zone_id    = local.zone_id
  setting_id = "ssl"
  value      = "strict"
}

resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = local.zone_id
  setting_id = "always_use_https"
  value      = "on"
}

resource "cloudflare_zone_setting" "security_header" {
  zone_id    = local.zone_id
  setting_id = "security_header"

  value = {
    strict_transport_security = {
      enabled            = true
      include_subdomains = true
      max_age            = 31536000
      nosniff            = true
      preload            = false
    }
  }
}

resource "cloudflare_zone_setting" "tls_1_3" {
  zone_id    = local.zone_id
  setting_id = "tls_1_3"
  value      = "on"
}

resource "cloudflare_zone_setting" "automatic_https_rewrites" {
  zone_id    = local.zone_id
  setting_id = "automatic_https_rewrites"
  value      = "on"
}

resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id    = local.zone_id
  setting_id = "min_tls_version"
  value      = "1.2"
}

resource "cloudflare_zone_setting" "http3" {
  zone_id    = local.zone_id
  setting_id = "http3"
  value      = "on"
}

resource "cloudflare_zone_setting" "brotli" {
  zone_id    = local.zone_id
  setting_id = "brotli"
  value      = "on"
}
