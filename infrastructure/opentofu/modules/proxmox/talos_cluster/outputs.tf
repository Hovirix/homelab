output "nodes" {
  value = {
    for name, node in module.node : name => {
      id        = node.id
      name      = node.name
      node_name = node.node_name
      vm_id     = node.vm_id
    }
  }
}
