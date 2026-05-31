resource "proxmox_virtual_environment_vm" "this" {
  name        = var.name
  node_name   = var.node_name
  vm_id       = var.vm_id
  description = var.description

  protection      = var.protection
  stop_on_destroy = var.stop_on_destroy

  cpu {
    cores = var.cpu_cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory_dedicated
  }

  disk {
    datastore_id = var.boot_disk.datastore_id
    import_from  = var.boot_disk.import_from
    interface    = var.boot_disk.interface
    iothread     = var.boot_disk.iothread
    discard      = var.boot_disk.discard
    size         = var.boot_disk.size
  }

  dynamic "disk" {
    for_each = var.data_disks

    content {
      datastore_id = disk.value.datastore_id
      interface    = disk.value.interface
      iothread     = disk.value.iothread
      discard      = disk.value.discard
      ssd          = disk.value.ssd
      size         = disk.value.size
    }
  }

  network_device {
    bridge  = var.network_bridge
    vlan_id = var.network_vlan_id
  }

  operating_system {
    type = "l26"
  }
}
