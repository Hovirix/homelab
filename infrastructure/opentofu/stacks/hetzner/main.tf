resource "hcloud_storage_box" "backups" {
  name             = "backups"
  storage_box_type = "bx11"
  location         = "fsn1"
  password         = var.hetzner_storage_box_password

  access_settings = {
    reachable_externally = true
    ssh_enabled          = true # SSH port 23 (interactive access)
  }

  delete_protection = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcloud_storage_box_subaccount" "homelab" {
  storage_box_id = hcloud_storage_box.backups.id

  name           = "homelab"
  home_directory = "homelab"
  password       = var.hetzner_storage_box_password
  description    = "Restic backups for HX Lab"

  access_settings = {
    reachable_externally = true
    ssh_enabled          = true
  }

  lifecycle {
    prevent_destroy = true
  }
}
