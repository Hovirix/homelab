output "id" {
  value = proxmox_virtual_environment_vm.this.id
}

output "name" {
  value = proxmox_virtual_environment_vm.this.name
}

output "proxmox_node" {
  value = proxmox_virtual_environment_vm.this.node_name
}

output "vm_id" {
  value = proxmox_virtual_environment_vm.this.vm_id
}
