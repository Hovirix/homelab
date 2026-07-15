variable "talos" {
  type = object({
    schematic_id = string
    version      = string
  })
}

variable "nodes" {
  type = map(object({
    proxmox_node = string
    vm_id        = number
    mac_address  = string
  }))
}

variable "vm" {
  type = object({
    cpu_cores = number
    memory_mb = number
  })
}

variable "protection" {
  type    = bool
  default = true
}

variable "network" {
  type = object({
    bridge  = string
    vlan_id = number
  })
}

variable "storage" {
  type = object({
    image_datastore = string
    boot_datastore  = string
    boot_disk_gb    = number
  })
}
