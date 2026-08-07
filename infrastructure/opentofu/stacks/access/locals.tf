locals {
  account_id = "2bcc2c0c19d1ad6037c19ed8fe4a0043"
  zone_id    = "da22c5c98b60f20eb6854c15af389d6c"
  domain     = "home.hovirix.dev"

  tunnel = {
    name       = "homelab"
    config_src = "cloudflare"
  }

  access_policies = {
    admins = {
      group             = "admins"
      allowed_countries = ["FR"]
    }

    users = {
      group             = "users"
      allowed_countries = ["FR"]
    }
  }

  apps = {
    authentik = {
      name     = "Authentik"
      hostname = "authentik.${local.domain}"

      cloudflare = {
        enabled       = true
        upstream      = "http://authentik_server:9000"
        access_policy = "admins"
      }
    }

    cloudflare = {
      name = "Cloudflare"

      authentik = {
        oauth = {
          enabled = true
          redirect_uris = [
            "https://hovirix.cloudflareaccess.com/cdn-cgi/access/callback",
          ]
        }
      }
    }

    grafana = {
      name     = "Grafana"
      hostname = "grafana.${local.domain}"

      authentik = {
        oauth = {
          enabled = true
          redirect_uris = [
            "https://grafana.${local.domain}/login/generic_oauth",
          ]
        }
      }

      cloudflare = {
        enabled       = true
        upstream      = "http://observability_grafana:3000"
        access_policy = "admins"
      }
    }

    immich = {
      name     = "Immich"
      hostname = "immich.${local.domain}"

      authentik = {
        oauth = {
          enabled = true
          redirect_uris = [
            "app.immich:///oauth-callback",
            "https://immich.${local.domain}/auth/login",
            "https://immich.${local.domain}/user-settings",
          ]
        }
      }

      cloudflare = {
        enabled       = true
        upstream      = "http://prod-apps-01.home.hovirix.dev:2283"
        access_policy = "admins"
      }
    }

    paperless = {
      name     = "Paperless"
      hostname = "paperless.${local.domain}"

      authentik = {
        oauth = {
          enabled = true
          redirect_uris = [
            "https://paperless.${local.domain}/accounts/oidc/authentik/login/callback/",
          ]
        }
      }

      cloudflare = {
        enabled       = true
        upstream      = "http://prod-apps-01.home.hovirix.dev:8000"
        access_policy = "admins"
      }
    }

    vaultwarden = {
      name     = "Vaultwarden"
      hostname = "vaultwarden.${local.domain}"

      cloudflare = {
        enabled       = true
        upstream      = "http://prod-apps-01.home.hovirix.dev:80"
        access_policy = "admins"
      }
    }
  }

  authentik_oauth_apps = {
    for slug, app in local.apps : slug => app
    if try(app.authentik.oauth.enabled, false)
  }

  cloudflare_apps = {
    for slug, app in local.apps : slug => app
    if try(app.cloudflare.enabled, false)
  }

  cloudflare_application_hostnames = {
    for slug, app in local.cloudflare_apps : slug => app.hostname
  }

  invalid_cloudflare_application_policies = [
    for slug, app in local.cloudflare_apps : "${slug}:${app.cloudflare.access_policy}"
    if !contains(keys(local.access_policies), app.cloudflare.access_policy)
  ]

  cloudflare_tunnel_ingress = concat(
    [
      for slug, app in local.cloudflare_apps : {
        hostname = local.cloudflare_application_hostnames[slug]
        service  = app.cloudflare.upstream
      }
    ],
    [
      {
        service = "http_status:404"
      }
    ]
  )

  cloudflare_access_policy_ids = {
    for name in keys(local.access_policies) : name => concat(
      [cloudflare_zero_trust_access_policy.allow[name].id],
      contains(keys(cloudflare_zero_trust_access_policy.country_restriction), name) ? [cloudflare_zero_trust_access_policy.country_restriction[name].id] : []
    )
  }
}
