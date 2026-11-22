resource "incus_storage_volume" "swarm" {
  name         = "swarm"
  pool         = "local"
  content_type = "filesystem"

  config = {
    "size"               = "1TB"
    "snapshots.schedule" = "@hourly"
    "snapshots.expiry"   = "1d"
  }

  lifecycle {
    prevent_destroy = true
  }
}
