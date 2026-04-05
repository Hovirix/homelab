resource "cloudflare_zero_trust_access_application" "this" {
  account_id = var.account_id

  name             = var.name
  type             = var.type
  session_duration = var.session_duration
  allowed_idps     = var.allowed_idps

  destinations = [
    {
      type = "public"
      uri  = var.hostname
    }
  ]

  policies = [for id in var.policy_ids : { id = id }]
}
