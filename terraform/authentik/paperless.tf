resource "authentik_provider_oauth2" "paperless" {
  name          = "Paperless"
  client_id     = data.sops_file.authentik_clients.data["oauth.paperless.client_id"]
  client_secret = data.sops_file.authentik_clients.data["oauth.paperless.client_secret"]

  authorization_flow = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow  = data.authentik_flow.default-provider-invalidation-flow.id

  allowed_redirect_uris = [{
    matching_mode = "strict"
    url           = "https://paperless.nemnix.site/accounts/oidc/authentik/login/callback/"
  }]
}

resource "authentik_application" "paperless" {
  name              = "Paperless"
  slug              = "paperless"
  protocol_provider = authentik_provider_oauth2.paperless.id
}
