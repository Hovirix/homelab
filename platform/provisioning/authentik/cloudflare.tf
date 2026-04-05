resource "authentik_provider_oauth2" "cloudflare" {
  name          = "Cloudflare"
  client_id     = data.sops_file.authentik_clients.data["oauth.cloudflare.client_id"]
  client_secret = data.sops_file.authentik_clients.data["oauth.cloudflare.client_secret"]

  authorization_flow = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow  = data.authentik_flow.default-provider-invalidation-flow.id

  allowed_redirect_uris = [{
    matching_mode = "strict",
    url           = "https://hovirix.cloudflareaccess.com/cdn-cgi/access/callback",
  }]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.profile.id,
    data.authentik_property_mapping_provider_scope.email.id,
  ]
}

resource "authentik_application" "cloudflare" {
  name              = "Cloudflare"
  slug              = "cloudflare"
  protocol_provider = authentik_provider_oauth2.cloudflare.id
}

