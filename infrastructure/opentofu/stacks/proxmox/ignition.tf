resource "proxmox_virtual_environment_file" "fcos_ignition" {
  content_type = "snippets"
  datastore_id = local.snippet_datastore_id
  node_name    = local.proxmox_node

  source_file {
    file_name = "fcos.ign"
    path      = local.fcos_ignition_file
  }
}
