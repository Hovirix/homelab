locals {
  talos_image_url = "https://factory.talos.dev/image/${var.talos_image_schematic_id}/${var.talos_version}/nocloud-amd64.raw.xz"
  proxmox_nodes   = toset([for node in values(var.nodes) : node.node_name])
}

resource "proxmox_virtual_environment_download_file" "talos_nocloud" {
  for_each = local.proxmox_nodes

  content_type = "import"
  datastore_id = var.image_datastore_id
  node_name    = each.key
  file_name    = "talos-${var.talos_version}-nocloud-amd64.raw.xz"
  url          = local.talos_image_url
}

module "node" {
  source = "../talos_vm"

  for_each = var.nodes

  name = each.key

  node_name = each.value.node_name
  vm_id     = each.value.vm_id

  cpu_cores        = var.cpu_cores
  memory_dedicated = var.memory_dedicated
  network_bridge   = var.network_bridge
  network_vlan_id  = var.network_vlan_id

  boot_disk = {
    datastore_id = var.boot_disk_datastore_id
    import_from  = proxmox_virtual_environment_download_file.talos_nocloud[each.value.node_name].id
    size         = var.boot_disk_size
  }
}
