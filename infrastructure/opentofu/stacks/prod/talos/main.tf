ephemeral "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = local.kubernetes_endpoint
  machine_type       = "controlplane"
  machine_secrets    = local.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version

  config_patches = [
    file("${path.module}/patches/controlplane.yaml"),
  ]
}

ephemeral "talos_client_configuration" "cluster" {
  cluster_name    = var.cluster_name
  machine_secrets = local.machine_secrets
  endpoints       = [var.controlplane.endpoint]
  nodes           = [var.controlplane.endpoint]
}

resource "talos_machine_configuration_apply" "controlplane" {
  node                           = var.controlplane.endpoint
  endpoint                       = var.controlplane.endpoint
  client_configuration_wo        = ephemeral.talos_client_configuration.cluster.client_configuration
  machine_configuration_input_wo = ephemeral.talos_machine_configuration.controlplane.machine_configuration
  config_patches                 = [local.node_patch]
}

resource "talos_machine_bootstrap" "cluster" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
  ]

  node                    = var.controlplane.endpoint
  endpoint                = var.controlplane.endpoint
  client_configuration_wo = ephemeral.talos_client_configuration.cluster.client_configuration
}

ephemeral "talos_cluster_kubeconfig" "cluster" {
  depends_on = [
    talos_machine_bootstrap.cluster,
  ]

  cluster_name    = var.cluster_name
  endpoint        = local.kubernetes_endpoint
  machine_secrets = local.machine_secrets
}
