ephemeral "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = var.cluster_endpoint
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
  endpoints       = [var.talos_endpoint]
  nodes           = local.controlplane_dns_names
}

resource "talos_machine_configuration_apply" "controlplanes" {
  for_each = var.controlplanes

  node                           = each.value.dns_name
  endpoint                       = each.value.dns_name
  client_configuration_wo        = ephemeral.talos_client_configuration.cluster.client_configuration
  machine_configuration_input_wo = ephemeral.talos_machine_configuration.controlplane.machine_configuration
  apply_mode                     = "auto"
  config_patches                 = [local.node_patches[each.key]]
}

resource "talos_machine_bootstrap" "cluster" {
  depends_on = [
    talos_machine_configuration_apply.controlplanes,
  ]

  node                    = local.bootstrap_node
  endpoint                = local.bootstrap_node
  client_configuration_wo = ephemeral.talos_client_configuration.cluster.client_configuration
}

ephemeral "talos_cluster_kubeconfig" "cluster" {
  depends_on = [
    talos_machine_bootstrap.cluster,
  ]

  cluster_name    = var.cluster_name
  endpoint        = var.cluster_endpoint
  machine_secrets = local.machine_secrets
}
