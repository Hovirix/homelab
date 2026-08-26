moved {
  from = authentik_provider_oauth2.app["grafana"]
  to   = authentik_provider_oauth2.grafana
}

moved {
  from = authentik_provider_oauth2.app["immich"]
  to   = authentik_provider_oauth2.immich
}

moved {
  from = authentik_provider_oauth2.app["paperless"]
  to   = authentik_provider_oauth2.paperless
}

moved {
  from = authentik_provider_oauth2.app["vaultwarden"]
  to   = authentik_provider_oauth2.vaultwarden
}
