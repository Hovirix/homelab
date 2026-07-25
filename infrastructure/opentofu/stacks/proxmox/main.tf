resource "proxmox_download_file" "talos_nocloud" {
  content_type        = "iso"
  datastore_id        = "local"
  file_name           = "talos-nocloud-amd64.iso"
  node_name           = local.controlplane.proxmox_node
  url                 = "https://factory.talos.dev/image/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/v1.13.3/nocloud-amd64.iso"
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_vm" "controlplane" {
  name        = local.controlplane.name
  node_name   = local.controlplane.proxmox_node
  vm_id       = local.controlplane.vm_id
  description = "Managed by OpenTofu"

  stop_on_destroy = true
  protection      = true

  boot_order = ["virtio0", "ide3"]

  cpu {
    cores = 10
    type  = "host"
  }

  memory {
    dedicated = 20480
  }

  disk {
    datastore_id = "local-zfs"
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 100
    file_format  = "raw"
  }

  cdrom {
    file_id = proxmox_download_file.talos_nocloud.id
  }

  network_device {
    bridge      = "vmbr0"
    vlan_id     = 40
    mac_address = local.controlplane.mac_address
  }

  operating_system {
    type = "l26"
  }
}
