resource "terraform_data" "ignition" {
  for_each = local.fcos_nodes

  input = file("${path.module}/build/${each.value.ignition_file}")
}
