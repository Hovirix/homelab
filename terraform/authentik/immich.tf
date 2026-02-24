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
      url           = "https://immich.nemnix.site/auth/login"
    },
    {
      matching_mode = "strict"
      url           = "https://immich.nemnix.site/user-settings"
    }
  ]
}

resource "authentik_application" "immich" {
  name              = "Immich"
  slug              = "immich"
  protocol_provider = authentik_provider_oauth2.immich.id
}
