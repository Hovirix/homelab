locals {
  authentik_oauth_apps = {
    for slug, app in local.apps : slug => app
    if can(app.redirect_uris)
  }
}

data "authentik_flow" "authorization" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "invalidation" {
  slug = "default-provider-invalidation-flow"
}

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

resource "authentik_provider_oauth2" "app" {
  for_each = local.authentik_oauth_apps

  name          = each.value.name
  client_id     = data.sops_file.identity.data["oauth.${each.key}.client_id"]
  client_secret = data.sops_file.identity.data["oauth.${each.key}.client_secret"]

  grant_types = ["authorization_code", "refresh_token"]

  authorization_flow    = data.authentik_flow.authorization.id
  invalidation_flow     = data.authentik_flow.invalidation.id
  access_token_validity = each.key == "vaultwarden" ? "minutes=10" : null
  signing_key           = each.key == "vaultwarden" ? data.authentik_certificate_key_pair.signing.id : null
  logout_method         = try(each.value.logout_method, null)
  logout_uri            = try(each.value.logout_uri, null)

  allowed_redirect_uris = [
    for uri in each.value.redirect_uris : {
      matching_mode = "strict"
      url           = uri
    }
  ]

  property_mappings = each.key == "vaultwarden" ? [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.profile.id,
    data.authentik_property_mapping_provider_scope.offline_access.id,
    authentik_property_mapping_provider_scope.email.id,
    ] : [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.profile.id,
    data.authentik_property_mapping_provider_scope.entitlements.id,
    authentik_property_mapping_provider_scope.email.id,
  ]
}

resource "authentik_application" "app" {
  for_each = local.authentik_oauth_apps

  name              = each.value.name
  slug              = each.key
  protocol_provider = authentik_provider_oauth2.app[each.key].id
}
