module "kubernetes_cluster" {
  source = "../../modules/proxmox/talos_cluster"

  talos = {
    schematic_id = "ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515"
    version      = "v1.13.3"
  }

  nodes = {
    prod-k8s-cp-01 = {
      proxmox_node = "pve1"
      vm_id        = 101
      mac_address  = "02:40:00:00:00:01"
    }

    # TODO: Enable when pve2 and pve3 are available
    # prod-k8s-cp-02 = {
    #   proxmox_node = "pve2"
    #   vm_id        = 102
    #   mac_address  = "02:40:00:00:00:02"
    # }

    # prod-k8s-cp-03 = {
    #   proxmox_node = "pve3"
    #   vm_id        = 103
    #   mac_address  = "02:40:00:00:00:03"
    # }
  }

  vm = {
    cpu_cores = 10
    memory_mb = 20480
  }

  network = {
    bridge  = "vmbr0"
    vlan_id = 40
  }

  storage = {
    image_datastore = "local"
    boot_datastore  = "local-zfs"
    boot_disk_gb    = 100
  }
}
