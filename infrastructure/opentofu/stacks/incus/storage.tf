resource "incus_storage_pool" "data" {
  name   = "data"
  driver = "zfs"

  config = {
    source = "data/incus"
  }

  lifecycle {
    prevent_destroy = true
  }
}
