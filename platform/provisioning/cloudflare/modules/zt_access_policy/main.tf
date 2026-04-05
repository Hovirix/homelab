resource "cloudflare_zero_trust_access_policy" "this" {
  account_id = var.account_id
  name       = var.name
  decision   = var.decision

  include = var.include
  require = var.require
  exclude = var.exclude

  session_duration = var.session_duration
}
