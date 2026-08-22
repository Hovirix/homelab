data "authentik_flow" "authorization" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "invalidation" {
  slug = "default-provider-invalidation-flow"
}

data "authentik_flow" "authentication" {
  slug = "default-authentication-flow"
}

data "authentik_stage" "authentication_mfa_validation" {
  name = "default-authentication-mfa-validation"
}

data "authentik_stage" "authenticator_totp_setup" {
  name = "default-authenticator-totp-setup"
}

data "authentik_stage" "authenticator_webauthn_setup" {
  name = "default-authenticator-webauthn-setup"
}
