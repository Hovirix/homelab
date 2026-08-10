resource "authentik_group" "app_users" {
  for_each = local.apps

  name = "${each.key}-users"
}
