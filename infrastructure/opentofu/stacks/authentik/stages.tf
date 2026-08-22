resource "authentik_stage_authenticator_validate" "authentication" {
  name                  = "default-authentication-mfa-validation"
  device_classes        = ["webauthn", "totp"]
  not_configured_action = "configure"
  configuration_stages = [
    data.authentik_stage.authenticator_webauthn_setup.id,
    data.authentik_stage.authenticator_totp_setup.id,
  ]
  webauthn_user_verification = "required"
}

import {
  to = authentik_stage_authenticator_validate.authentication
  id = data.authentik_stage.authentication_mfa_validation.id
}
