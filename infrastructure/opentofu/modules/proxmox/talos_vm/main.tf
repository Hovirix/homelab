resource "proxmox_virtual_environment_vm" "this" {
  name        = var.name
  node_name   = var.proxmox_node
  vm_id       = var.vm_id
  description = "Managed by OpenTofu"

  stop_on_destroy = true

  cpu {
    cores = var.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    datastore_id = var.boot_disk.datastore_id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = var.boot_disk.size_gb
    file_format  = "raw"
  }

  cdrom {
    file_id = var.iso_file_id
  }

  network_device {
    bridge      = var.network.bridge
    vlan_id     = var.network.vlan_id
    mac_address = var.network.mac_address
  }

  operating_system {
    type = "l26"
  }
}
