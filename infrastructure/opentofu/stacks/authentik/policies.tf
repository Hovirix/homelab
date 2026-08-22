data "authentik_property_mapping_provider_scope" "openid" {
  name = "authentik default OAuth Mapping: OpenID 'openid'"
}

data "authentik_property_mapping_provider_scope" "profile" {
  name = "authentik default OAuth Mapping: OpenID 'profile'"
}

data "authentik_property_mapping_provider_scope" "offline_access" {
  name = "authentik default OAuth Mapping: OpenID 'offline_access'"
}

data "authentik_property_mapping_provider_scope" "entitlements" {
  name = "authentik default OAuth Mapping: Application Entitlements"
}

data "authentik_certificate_key_pair" "signing" {
  name = "authentik Self-signed Certificate"
}

resource "authentik_property_mapping_provider_scope" "email" {
  name       = "Vaultwarden Email Scope"
  scope_name = "email"
  expression = "return {\"email\": request.user.email, \"email_verified\": True}"
}
