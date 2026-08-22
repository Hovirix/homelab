resource "authentik_provider_oauth2" "vaultwarden" {
  name          = "Vaultwarden"
  client_id     = data.sops_file.identity.data["oauth.vaultwarden.client_id"]
  client_secret = data.sops_file.identity.data["oauth.vaultwarden.client_secret"]

  grant_types           = ["authorization_code", "refresh_token"]
  authorization_flow    = data.authentik_flow.authorization.id
  invalidation_flow     = data.authentik_flow.invalidation.id
  access_token_validity = "minutes=10"
  signing_key           = data.authentik_certificate_key_pair.signing.id

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://vaultwarden.${local.domain}/identity/connect/oidc-signin"
    },
  ]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.profile.id,
    data.authentik_property_mapping_provider_scope.offline_access.id,
    authentik_property_mapping_provider_scope.email.id,
  ]
}

resource "authentik_application" "vaultwarden" {
  name              = "Vaultwarden"
  slug              = "vaultwarden"
  protocol_provider = authentik_provider_oauth2.vaultwarden.id
}
