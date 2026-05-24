resource "authentik_provider_oauth2" "immich" {
  name          = "Immich"
  client_id     = data.sops_file.authentik_clients.data["oauth.immich.client_id"]
  client_secret = data.sops_file.authentik_clients.data["oauth.immich.client_secret"]

  authorization_flow = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow  = data.authentik_flow.default-provider-invalidation-flow.id

  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = "app.immich:///oauth-callback"
    },
    {
      matching_mode = "strict"
      url           = "https://immich.home.hovirix.dev/auth/login"
    },
    {
      matching_mode = "strict"
      url           = "https://immich.home.hovirix.dev/user-settings"
    }
  ]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.profile.id,
    data.authentik_property_mapping_provider_scope.email.id,
  ]
}

resource "authentik_application" "immich" {
  name              = "Immich"
  slug              = "immich"
  protocol_provider = authentik_provider_oauth2.immich.id
}
