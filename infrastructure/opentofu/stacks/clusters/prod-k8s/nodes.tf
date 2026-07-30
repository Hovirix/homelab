locals {
  nodes = {
    cp1 = {
      hostname     = "prod-k8s-cp-01"
      fqdn         = "prod-k8s-cp-01.${local.domain}"
      ip           = "10.40.0.11"
      mac_address  = "02:40:00:00:00:01"
      proxmox_node = "pve1"
      vm_id        = 101
      machine_type = "controlplane"
      enabled      = true
    }

    cp2 = {
      hostname     = "prod-k8s-cp-02"
      fqdn         = "prod-k8s-cp-02.${local.domain}"
      ip           = "10.40.0.12"
      mac_address  = "02:40:00:00:00:02"
      proxmox_node = "pve2"
      vm_id        = 102
      machine_type = "controlplane"
      enabled      = false
    }

    cp3 = {
      hostname     = "prod-k8s-cp-03"
      fqdn         = "prod-k8s-cp-03.${local.domain}"
      ip           = "10.40.0.13"
      mac_address  = "02:40:00:00:00:03"
      proxmox_node = "pve3"
      vm_id        = 103
      machine_type = "controlplane"
      enabled      = false
    }
  }
}
