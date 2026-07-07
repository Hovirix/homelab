ephemeral "talos_client_configuration" "cluster" {
  cluster_name    = var.cluster.name
  machine_secrets = local.machine_secrets
  endpoints       = local.talos_endpoints
  nodes           = local.talos_nodes
}

ephemeral "talos_cluster_kubeconfig" "cluster" {
  depends_on = [
    talos_machine_bootstrap.cluster,
  ]

  cluster_name    = var.cluster.name
  endpoint        = local.cluster_endpoint
  machine_secrets = local.machine_secrets
}
