locals {
  account_id = "2bcc2c0c19d1ad6037c19ed8fe4a0043"
  zone_id    = "da22c5c98b60f20eb6854c15af389d6c"
  domain     = "home.hovirix.dev"

  exposed_apps = {
    authentik = {
      hostname = "authentik.${local.domain}"
      service  = "http://prod-idp-01.home.hovirix.dev:9000"
      access   = "admins"
    }

    immich = {
      hostname = "immich.${local.domain}"
      service  = "http://prod-apps-01.home.hovirix.dev:2283"
      access   = "admins"
    }

    paperless = {
      hostname = "paperless.${local.domain}"
      service  = "http://prod-apps-01.home.hovirix.dev:8000"
      access   = "admins"
    }

    vaultwarden = {
      hostname = "vaultwarden.${local.domain}"
      service  = "http://prod-apps-01.home.hovirix.dev:80"
      access   = "admins"
    }

    grafana = {
      hostname = "grafana.${local.domain}"
      service  = "http://prod-monitoring-01.home.hovirix.dev:3000"
      access   = "admins"
    }
  }

  tunnel_ingress = concat(
    [
      for app in values(local.exposed_apps) : {
        hostname = app.hostname
        service  = app.service
      }
    ],
    [
      {
        service = "http_status:404"
      }
    ]
  )

  access_policy_ids = {
    admins = [
      module.policy_authentik_admins.id,
      module.policy_block_non_fr.id,
    ]
    users = [
      module.policy_authentik_users.id,
      module.policy_block_non_fr.id,
    ]
  }
}
