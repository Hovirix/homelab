data "talos_machine_configuration" "controlplane" {
  cluster_name       = local.cluster_name
  cluster_endpoint   = local.cluster_endpoint
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.cluster.machine_secrets
  talos_version      = local.talos_version
  kubernetes_version = local.kubernetes_version

  config_patches = [
    local.machine_patch,
  ]
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = local.nodes

  node                        = each.value.ip
  client_configuration        = talos_machine_secrets.cluster.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  config_patches = [
    local.dhcp_patch,
    local.vip_patch,
  ]
}

resource "talos_machine_bootstrap" "cluster" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
  ]

  node                 = local.bootstrap_node.ip
  client_configuration = talos_machine_secrets.cluster.client_configuration
}
