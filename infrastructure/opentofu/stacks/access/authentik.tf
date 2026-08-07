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

data "authentik_property_mapping_provider_scope" "email" {
  name = "authentik default OAuth Mapping: OpenID 'email'"
}

resource "authentik_provider_oauth2" "app" {
  for_each = local.authentik_oauth_apps

  name          = each.value.name
  client_id     = data.sops_file.identity.data["oauth.${each.key}.client_id"]
  client_secret = data.sops_file.identity.data["oauth.${each.key}.client_secret"]

  grant_types = ["authorization_code", "refresh_token"]

  authorization_flow = data.authentik_flow.authorization.id
  invalidation_flow  = data.authentik_flow.invalidation.id

  allowed_redirect_uris = [
    for uri in each.value.authentik.oauth.redirect_uris : {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = uri
    }
  ]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.profile.id,
    data.authentik_property_mapping_provider_scope.email.id,
    authentik_property_mapping_provider_scope.groups.id,
  ]
}

resource "authentik_application" "app" {
  for_each = local.authentik_oauth_apps

  name              = each.value.name
  slug              = each.key
  protocol_provider = authentik_provider_oauth2.app[each.key].id
}

resource "authentik_property_mapping_provider_scope" "groups" {
  name       = "authentik default OAuth Mapping: OpenID 'groups'"
  scope_name = "groups"
  expression = "{\"groups\": [group.name for group in ak_user.groups.all()]}"
}

resource "authentik_group" "admins" {
  name         = "admins"
  is_superuser = true
  users        = [6]
}

resource "authentik_group" "users" {
  name = "users"
}
