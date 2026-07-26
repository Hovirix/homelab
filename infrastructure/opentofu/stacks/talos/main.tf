data "talos_machine_configuration" "controlplane" {
  cluster_name       = local.cluster.name
  cluster_endpoint   = local.cluster_endpoint
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.cluster.machine_secrets
  talos_version      = local.cluster.talos_version
  kubernetes_version = local.cluster.kubernetes_version

  config_patches = [
    file("${path.module}/patches/controlplane.yaml"),
  ]
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = local.controlplane_nodes

  node                        = each.value.hostname
  endpoint                    = each.value.hostname
  client_configuration        = talos_machine_secrets.cluster.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  config_patches              = [local.controlplane_node_patches[each.key]]
}

resource "talos_machine_bootstrap" "cluster" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
  ]

  node                 = local.bootstrap_node.hostname
  client_configuration = talos_machine_secrets.cluster.client_configuration
}
