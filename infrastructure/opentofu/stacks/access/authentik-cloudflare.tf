resource "authentik_provider_oauth2" "cloudflare" {
  name          = "Cloudflare"
  client_id     = data.sops_file.identity.data["oauth.cloudflare.client_id"]
  client_secret = data.sops_file.identity.data["oauth.cloudflare.client_secret"]

  grant_types = ["authorization_code", "refresh_token"]

  authorization_flow = data.authentik_flow.authorization.id
  invalidation_flow  = data.authentik_flow.invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = "https://hovirix.cloudflareaccess.com/cdn-cgi/access/callback"
    },
  ]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.profile.id,
    authentik_property_mapping_provider_scope.email.id,
  ]
}

resource "authentik_application" "cloudflare" {
  name              = "Cloudflare"
  slug              = "cloudflare"
  protocol_provider = authentik_provider_oauth2.cloudflare.id
}
