locals {
  talos_image_url = "https://factory.talos.dev/image/${var.talos.schematic_id}/${var.talos.version}/nocloud-amd64.iso"
  proxmox_nodes   = toset([for node in values(var.nodes) : node.proxmox_node])
}

resource "proxmox_download_file" "talos_nocloud" {
  for_each = local.proxmox_nodes

  content_type        = "iso"
  datastore_id        = var.storage.image_datastore
  node_name           = each.key
  url                 = local.talos_image_url
  overwrite_unmanaged = true
}

module "node" {
  source = "../talos_vm"

  for_each = var.nodes

  name = each.key

  proxmox_node = each.value.proxmox_node
  vm_id        = each.value.vm_id

  cpu_cores = var.vm.cpu_cores
  memory_mb = var.vm.memory_mb

  iso_file_id = proxmox_download_file.talos_nocloud[each.value.proxmox_node].id

  network = {
    bridge  = var.network.bridge
    vlan_id = var.network.vlan_id
  }

  boot_disk = {
    datastore_id = var.storage.boot_datastore
    size_gb      = var.storage.boot_disk_gb
  }
}
