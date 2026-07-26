resource "talos_machine_secrets" "cluster" {
  talos_version = local.cluster.talos_version

  lifecycle {
    prevent_destroy = true
  }
}

data "talos_client_configuration" "cluster" {
  cluster_name         = local.cluster.name
  client_configuration = talos_machine_secrets.cluster.client_configuration
  endpoints            = local.talos_endpoints
  nodes                = local.talos_nodes
}

resource "talos_cluster_kubeconfig" "cluster" {
  depends_on = [
    talos_machine_bootstrap.cluster,
  ]

  client_configuration = talos_machine_secrets.cluster.client_configuration
  node                 = local.bootstrap_node.hostname
  endpoint             = local.bootstrap_node.hostname
}
