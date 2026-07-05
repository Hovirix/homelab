variable "name" {
  type = string
}

variable "proxmox_node" {
  type = string
}

variable "vm_id" {
  type = number
}

variable "cpu_cores" {
  type = number
}

variable "memory_mb" {
  type = number
}

variable "iso_file_id" {
  type = string
}

variable "boot_disk" {
  type = object({
    datastore_id = string
    size_gb      = number
  })
}

variable "network" {
  type = object({
    bridge      = string
    vlan_id     = number
    mac_address = string
  })
}
