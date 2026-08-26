resource "authentik_provider_oauth2" "grafana" {
  name          = "Grafana"
  client_id     = data.sops_file.identity.data["oauth.grafana.client_id"]
  client_secret = data.sops_file.identity.data["oauth.grafana.client_secret"]

  grant_types = ["authorization_code", "refresh_token"]

  authorization_flow = data.authentik_flow.authorization.id
  invalidation_flow  = data.authentik_flow.invalidation.id
  logout_method      = "frontchannel"
  logout_uri         = "https://grafana.${local.domain}/logout"

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://grafana.${local.domain}/login/generic_oauth"
    },
  ]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.profile.id,
    data.authentik_property_mapping_provider_scope.entitlements.id,
    authentik_property_mapping_provider_scope.email.id,
  ]
}

resource "authentik_application" "grafana" {
  name              = "Grafana"
  slug              = "grafana"
  protocol_provider = authentik_provider_oauth2.grafana.id
}
