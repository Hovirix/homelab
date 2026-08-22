resource "authentik_provider_oauth2" "immich" {
  name          = "Immich"
  client_id     = data.sops_file.identity.data["oauth.immich.client_id"]
  client_secret = data.sops_file.identity.data["oauth.immich.client_secret"]

  grant_types = ["authorization_code", "refresh_token"]

  authorization_flow = data.authentik_flow.authorization.id
  invalidation_flow  = data.authentik_flow.invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "app.immich:///oauth-callback"
    },
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://immich.${local.domain}/auth/login"
    },
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://immich.${local.domain}/user-settings"
    },
  ]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.profile.id,
    data.authentik_property_mapping_provider_scope.entitlements.id,
    authentik_property_mapping_provider_scope.email.id,
  ]
}

resource "authentik_application" "immich" {
  name              = "Immich"
  slug              = "immich"
  protocol_provider = authentik_provider_oauth2.immich.id
}
