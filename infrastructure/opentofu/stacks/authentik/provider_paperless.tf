resource "authentik_provider_oauth2" "paperless" {
  name          = "Paperless"
  client_id     = data.sops_file.identity.data["oauth.paperless.client_id"]
  client_secret = data.sops_file.identity.data["oauth.paperless.client_secret"]

  grant_types = ["authorization_code", "refresh_token"]

  authorization_flow = data.authentik_flow.authorization.id
  invalidation_flow  = data.authentik_flow.invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://paperless.${local.domain}/accounts/oidc/authentik/login/callback/"
    },
  ]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.profile.id,
    data.authentik_property_mapping_provider_scope.entitlements.id,
    authentik_property_mapping_provider_scope.email.id,
  ]
}

resource "authentik_application" "paperless" {
  name              = "Paperless"
  slug              = "paperless"
  protocol_provider = authentik_provider_oauth2.paperless.id
}
