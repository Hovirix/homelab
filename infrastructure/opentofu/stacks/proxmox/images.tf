resource "proxmox_download_file" "fcos_image" {
  content_type = "iso"
  datastore_id = local.image_datastore_id
  node_name    = local.proxmox_node

  checksum           = local.fcos_checksum
  checksum_algorithm = "sha256"
  file_name          = local.fcos_image_file_name
  url                = local.fcos_download_url

  decompression_algorithm = "zst"
  overwrite               = false
}
