locals {
  proxmox_node         = "pve1"
  image_datastore_id   = "local"
  snippet_datastore_id = "local"
  vm_datastore_id      = "local-zfs"
  network_bridge       = "vmbr0"
  fcos_image_file_name = "fedora-coreos-stable-proxmoxve.qcow2.img"

  fcos_config        = yamldecode(file("${path.module}/fcos/nodes.yaml"))
  fcos_nodes         = local.fcos_config.hosts
  fcos_ignition_file = "${path.module}/build/fcos.ign"

  fcos_metadata       = jsondecode(data.http.fcos_stable.response_body)
  fcos_proxmoxve_disk = local.fcos_metadata.architectures.x86_64.artifacts.proxmoxve.formats["qcow2.xz"].disk
  fcos_download_url   = local.fcos_proxmoxve_disk.location
  fcos_checksum       = local.fcos_proxmoxve_disk.sha256
}
