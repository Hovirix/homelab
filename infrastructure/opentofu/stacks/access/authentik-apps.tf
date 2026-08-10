resource "authentik_provider_oauth2" "app" {
  for_each = local.apps

  name          = each.value.name
  client_id     = data.sops_file.identity.data["oauth.${each.key}.client_id"]
  client_secret = data.sops_file.identity.data["oauth.${each.key}.client_secret"]

  grant_types = ["authorization_code", "refresh_token"]

  authorization_flow    = data.authentik_flow.authorization.id
  invalidation_flow     = data.authentik_flow.invalidation.id
  access_token_validity = lookup(each.value, "access_token_validity", null)
  signing_key           = lookup(each.value, "signed_tokens", false) ? data.authentik_certificate_key_pair.signing.id : null
  logout_method         = lookup(each.value, "logout_method", null)
  logout_uri            = lookup(each.value, "logout_uri", null)

  allowed_redirect_uris = [
    for uri in each.value.redirect_uris : {
      matching_mode = "strict"
      url           = uri
    }
  ]

  property_mappings = lookup(each.value, "offline_access", false) ? [
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
  for_each = local.apps

  name              = each.value.name
  slug              = each.key
  protocol_provider = authentik_provider_oauth2.app[each.key].id
}
