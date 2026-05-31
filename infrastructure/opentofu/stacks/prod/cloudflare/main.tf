module "zero_trust_access" {
  source = "../../../modules/cloudflare/zero_trust_access"

  account_id = "2bcc2c0c19d1ad6037c19ed8fe4a0043"
  zone_id    = "da22c5c98b60f20eb6854c15af389d6c"
  domain     = "home.hovirix.dev"

  tunnel = {
    name       = "homelab"
    config_src = "cloudflare"
  }

  identity_provider = {
    name          = "authentik"
    client_id     = data.sops_file.authentik_clients.data["oauth.cloudflare.client_id"]
    client_secret = data.sops_file.authentik_clients.data["oauth.cloudflare.client_secret"]
    auth_url      = "https://authentik.home.hovirix.dev/application/o/authorize/"
    token_url     = "https://authentik.home.hovirix.dev/application/o/token/"
    certs_url     = "https://authentik.home.hovirix.dev/application/o/cloudflare/jwks/"
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

  applications = {
    authentik = {
      upstream      = "http://prod-idp-01.home.hovirix.dev:9000"
      access_policy = "admins"
    }

    immich = {
      upstream      = "http://prod-apps-01.home.hovirix.dev:2283"
      access_policy = "admins"
    }

    paperless = {
      upstream      = "http://prod-apps-01.home.hovirix.dev:8000"
      access_policy = "admins"
    }

    vaultwarden = {
      upstream      = "http://prod-apps-01.home.hovirix.dev:80"
      access_policy = "admins"
    }

    grafana = {
      upstream      = "http://prod-monitoring-01.home.hovirix.dev:3000"
      access_policy = "admins"
    }
  }
}
