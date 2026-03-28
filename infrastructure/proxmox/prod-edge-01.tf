resource "proxmox_virtual_environment_vm" "prod_edge_01" {
  name        = "prod-edge-01"
  node_name   = "infra-01"
  vm_id       = 200
  description = "Managed by Terraform"

  protection      = false
  stop_on_destroy = true

  cpu {
    cores = 1
    type  = "host"
  }

  memory {
    dedicated = 1024
  }

  disk {
    datastore_id = "local-zfs"
    import_from  = proxmox_virtual_environment_download_file.fedora_cloud_image_infra.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
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
        address = "10.20.0.10/24"
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
