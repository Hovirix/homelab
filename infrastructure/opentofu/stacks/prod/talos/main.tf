ephemeral "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster.name
  cluster_endpoint   = local.cluster_endpoint
  machine_type       = "controlplane"
  machine_secrets    = local.machine_secrets
  talos_version      = var.cluster.talos_version
  kubernetes_version = var.cluster.kubernetes_version

  config_patches = [
    file("${path.module}/patches/controlplane.yaml"),
  ]
}

resource "talos_machine_configuration_apply" "controlplane" {
  node                           = local.bootstrap_node
  endpoint                       = local.bootstrap_node
  client_configuration_wo        = ephemeral.talos_client_configuration.cluster.client_configuration
  machine_configuration_input_wo = ephemeral.talos_machine_configuration.controlplane.machine_configuration
  config_patches                 = [local.controlplane_node_patch]
}

resource "talos_machine_bootstrap" "cluster" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
  ]

  node                    = local.bootstrap_node
  client_configuration_wo = ephemeral.talos_client_configuration.cluster.client_configuration
}
