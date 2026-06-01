module "kubernetes_cluster" {
  source = "../../../modules/proxmox/talos_cluster"

  talos_image_schematic_id = "ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515"
  talos_version            = "v1.13.3"

  nodes = {
    prod-k8s-01 = {
      node_name = "pve1"
      vm_id     = 101
    }

    # TODO: Enable when pve2 and pve3 are available
    # prod-k8s-02 = {
    #   node_name = "pve2"
    #   vm_id     = 102
    # }

    # prod-k8s-03 = {
    #   node_name = "pve3"
    #   vm_id     = 103
    # }
  }

  cpu_cores              = 4
  memory_dedicated       = 8192
  network_vlan_id        = 40
  boot_disk_datastore_id = "local-lvm"
  boot_disk_size         = 100
}
