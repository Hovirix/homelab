output "nodes" {
  value = {
    for name, node in module.node : name => {
      id           = node.id
      name         = node.name
      proxmox_node = node.proxmox_node
      vm_id        = node.vm_id
    }
  }
}
