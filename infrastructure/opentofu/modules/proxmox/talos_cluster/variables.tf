variable "talos_image_schematic_id" {
  type = string
}

variable "talos_version" {
  type = string
}

variable "nodes" {
  type = map(object({
    node_name = string
    vm_id     = number
  }))
}

variable "cpu_cores" {
  type = number
}

variable "memory_dedicated" {
  type = number
}

variable "network_vlan_id" {
  type = number
}

variable "image_datastore_id" {
  type    = string
  default = "local"
}

variable "boot_disk_datastore_id" {
  type    = string
  default = "local-zfs"
}

variable "boot_disk_size" {
  type = number
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}
