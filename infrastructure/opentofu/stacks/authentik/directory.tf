data "authentik_user" "akadmin" {
  username = "akadmin"
}

resource "authentik_user" "akadmin" {
  username = data.authentik_user.akadmin.username
  groups = distinct(concat(data.authentik_user.akadmin.groups, [
    authentik_group.grafana_admins.id,
    authentik_group.paperless_users.id,
    authentik_group.vaultwarden_users.id,
  ]))

  lifecycle {
    ignore_changes = [
      attributes,
      email,
      is_active,
      name,
      path,
      roles,
      type,
    ]
  }
}

import {
  to = authentik_user.akadmin
  id = data.authentik_user.akadmin.id
}
