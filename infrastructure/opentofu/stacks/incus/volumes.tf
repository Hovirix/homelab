resource "incus_storage_volume" "swarm" {
  name         = "swarm"
  pool         = incus_storage_pool.data.name
  content_type = "filesystem"

  config = {
    "security.shifted"   = "true"
    "snapshots.schedule" = "@hourly"
    "snapshots.expiry"   = "1d"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "incus_storage_volume" "backups" {
  name         = "backups"
  pool         = incus_storage_pool.data.name
  content_type = "filesystem"

  config = {
    "security.shifted" = "true"
  }

  lifecycle {
    prevent_destroy = true
  }
}
