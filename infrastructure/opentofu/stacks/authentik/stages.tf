resource "authentik_stage_authenticator_totp" "mfa" {
  name = "MFA TOTP Setup"
}

resource "authentik_stage_authenticator_webauthn" "mfa" {
  name = "MFA WebAuthn Setup"
}

resource "authentik_stage_authenticator_validate" "mfa" {
  name                  = "MFA Validation"
  device_classes        = ["totp", "webauthn"]
  not_configured_action = "configure"
  configuration_stages = [
    authentik_stage_authenticator_totp.mfa.id,
    authentik_stage_authenticator_webauthn.mfa.id,
  ]
}

resource "authentik_flow_stage_binding" "authentication_mfa" {
  target = data.authentik_flow.authentication.id
  stage  = authentik_stage_authenticator_validate.mfa.id
  order  = 30
}
