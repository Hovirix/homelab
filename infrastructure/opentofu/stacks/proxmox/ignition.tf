resource "proxmox_virtual_environment_file" "fcos_ignition" {
  for_each = local.fcos_nodes

  content_type = "snippets"
  datastore_id = local.snippet_datastore_id
  node_name    = local.proxmox_node

  source_file {
    file_name = each.value.ignition_file
    path      = "${path.module}/build/${each.value.ignition_file}"
  }
}
