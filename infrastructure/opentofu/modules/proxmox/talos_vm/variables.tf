variable "name" {
  type = string
}

variable "node_name" {
  type = string
}

variable "vm_id" {
  type = number
}

variable "description" {
  type    = string
  default = "Managed by OpenTofu"
}

variable "protection" {
  type    = bool
  default = false
}

variable "stop_on_destroy" {
  type    = bool
  default = true
}

variable "cpu_cores" {
  type = number
}

variable "cpu_type" {
  type    = string
  default = "host"
}

variable "memory_dedicated" {
  type = number
}

variable "boot_disk" {
  type = object({
    datastore_id = string
    import_from  = string
    interface    = optional(string, "virtio0")
    iothread     = optional(bool, true)
    discard      = optional(string, "on")
    size         = number
  })
}

variable "data_disks" {
  type = list(object({
    datastore_id = string
    interface    = string
    iothread     = optional(bool, true)
    discard      = optional(string, "on")
    ssd          = optional(bool, true)
    size         = number
  }))
  default = []
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "network_vlan_id" {
  type = number
}
