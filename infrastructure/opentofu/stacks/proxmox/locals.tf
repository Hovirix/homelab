locals {
  domain = "home.hovirix.dev"

  controlplane_nodes = {
    prod-k8s-cp-01 = {
      name         = "prod-k8s-cp-01"
      proxmox_node = "pve1"
      vm_id        = 101
      mac_address  = "02:40:00:00:00:01"
    }

    # TODO: Enable when pve2 is available
    # prod-k8s-cp-02 = {
    #   proxmox_node = "pve2"
    #   vm_id        = 102
    #   mac_address  = "02:40:00:00:00:02"
    # }

    # TODO: Enable when pve3 is available
    # prod-k8s-cp-03 = {
    #   proxmox_node = "pve3"
    #   vm_id        = 103
    #   mac_address  = "02:40:00:00:00:03"
    # }
  }

  controlplane = local.controlplane_nodes["prod-k8s-cp-01"]
}
