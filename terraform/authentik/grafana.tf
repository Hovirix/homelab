resource "authentik_provider_oauth2" "grafana" {
  name          = "Grafana"
  client_id     = data.sops_file.authentik_clients.data["oauth.grafana.client_id"]
  client_secret = data.sops_file.authentik_clients.data["oauth.grafana.client_secret"]

  authorization_flow = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow  = data.authentik_flow.default-provider-invalidation-flow.id

  allowed_redirect_uris = [{
    matching_mode = "strict",
    url           = "https://grafana.nemnix.site/login/generic_oauth",
  }]
}

resource "authentik_application" "grafana" {
  name              = "Grafana"
  slug              = "grafana"
  protocol_provider = authentik_provider_oauth2.grafana.id
}
