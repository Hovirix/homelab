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
  }))
}

variable "vm" {
  type = object({
    cpu_cores = number
    memory_mb = number
  })
}

variable "network" {
  type = object({
    bridge  = optional(string, "vmbr0")
    vlan_id = number
  })
}

variable "storage" {
  type = object({
    image_datastore = optional(string, "local")
    boot_datastore  = optional(string, "local-zfs")
    boot_disk_gb    = number
  })
}
