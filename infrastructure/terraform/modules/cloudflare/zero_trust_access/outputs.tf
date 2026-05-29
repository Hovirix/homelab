output "identity_provider_id" {
  value = module.identity_provider.id
}

output "tunnel_id" {
  value = module.tunnel.id
}

output "tunnel_cname" {
  value = module.tunnel.cname
}

output "application_ids" {
  value = {
    for name, app in module.applications : name => app.id
  }
}

output "application_audiences" {
  value = {
    for name, app in module.applications : name => app.aud
  }
}

output "dns_record_ids" {
  value = {
    for name, app in module.applications : name => app.dns_record_id
  }
}
