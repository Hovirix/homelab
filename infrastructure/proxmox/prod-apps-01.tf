resource "proxmox_virtual_environment_vm" "prod_apps_01" {
  name        = "prod-apps-01"
  node_name   = "compute-01"
  vm_id       = 400
  description = "Managed by Terraform"

  protection      = false
  stop_on_destroy = true

  startup {
    order      = "1"
    up_delay   = "60"
    down_delay = "60"
  }

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

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = "local-zfs"

    ip_config {
      ipv4 {
        address = "dhcp"
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
