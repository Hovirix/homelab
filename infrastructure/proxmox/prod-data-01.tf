resource "proxmox_virtual_environment_vm" "prod_data_01" {
  name        = "prod-data-01"
  node_name   = "compute-01"
  vm_id       = 300
  description = "Managed by Terraform"

  protection      = false
  stop_on_destroy = true

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-zfs"
    import_from  = proxmox_virtual_environment_download_file.fedora_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  disk {
    datastore_id = "data"
    interface    = "scsi1"
    iothread     = true
    discard      = "on"
    ssd          = true
    size         = 200
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = 20
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = "local-zfs"

    ip_config {
      ipv4 {
        address = "10.20.0.50/24"
        gateway = "10.20.0.1"
      }
    }

    user_account {
      username = "fedora"
      keys = [
        trimspace(file("~/.ssh/id_ed25519.pub"))
      ]
    }
  }
}
