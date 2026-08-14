resource "proxmox_virtual_environment_vm" "fcos" {
  for_each = local.fcos_nodes

  name        = each.key
  description = "Managed by OpenTofu"

  node_name = local.proxmox_node
  vm_id     = each.value.vm_id

  stop_on_destroy = true
  protection      = false

  cpu {
    cores = each.value.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory_mb
  }

  disk {
    datastore_id = local.vm_datastore_id
    file_id      = proxmox_download_file.fcos_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = each.value.boot_disk_gb
    file_format  = "raw"
  }

  virtiofs {
    mapping   = proxmox_hardware_mapping_dir.swarm.name
    cache     = "auto"
    direct_io = true
  }

  network_device {
    bridge      = local.network_bridge
    mac_address = each.value.mac
    vlan_id     = local.fcos_config.network.vlan_id
  }

  initialization {
    datastore_id        = local.vm_datastore_id
    vendor_data_file_id = proxmox_virtual_environment_file.fcos_ignition.id
  }

  operating_system {
    type = "l26"
  }
}
