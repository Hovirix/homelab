output "id" {
  value = module.access_application.id
}

output "aud" {
  value = module.access_application.aud
}

output "domain" {
  value = module.access_application.domain
}

output "dns_record_id" {
  value = cloudflare_dns_record.this.id
}

output "tunnel_ingress" {
  value = {
    hostname = var.hostname
    service  = var.service
  }
}
