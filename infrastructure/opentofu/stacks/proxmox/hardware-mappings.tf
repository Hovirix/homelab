resource "proxmox_hardware_mapping_dir" "swarm" {
  name    = "swarm"
  comment = "Docker Swarm persistent data"

  map = [
    {
      node = local.proxmox_node
      path = "/rpool/swarm"
    }
  ]
}
