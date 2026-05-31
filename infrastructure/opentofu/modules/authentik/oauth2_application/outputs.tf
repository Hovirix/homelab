output "provider_id" {
  value = authentik_provider_oauth2.this.id
}

output "application_id" {
  value = authentik_application.this.id
}
