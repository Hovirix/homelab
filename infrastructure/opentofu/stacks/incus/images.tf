resource "incus_image" "fcos" {
  source_file = {
    data_path     = "${path.module}/build/fcos-proxmoxve.qcow2"
    metadata_path = "${path.module}/build/metadata.tar"
  }
}
