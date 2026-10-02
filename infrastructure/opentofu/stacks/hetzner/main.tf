resource "hcloud_storage_box" "backups" {
  name             = "backups"
  storage_box_type = "bx11"
  location         = "fsn1"
  password         = data.sops_file.infrastructure.data["hetzner.storage_box_password"]

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
  password       = data.sops_file.infrastructure.data["backup.sftp_password"]
  description    = "Restic backups for HX Lab"

  access_settings = {
    reachable_externally = true
  }

  lifecycle {
    prevent_destroy = true
  }
}
