resource "talos_machine_secrets" "cluster" {
  talos_version = local.talos_version

  lifecycle {
    prevent_destroy = true
  }
}

data "talos_client_configuration" "cluster" {
  cluster_name         = local.cluster_name
  client_configuration = talos_machine_secrets.cluster.client_configuration
  endpoints            = [for node in values(local.nodes) : node.hostname]
  nodes                = [for node in values(local.nodes) : node.ip]
}

resource "talos_cluster_kubeconfig" "cluster" {
  depends_on = [
    talos_machine_bootstrap.cluster,
  ]

  client_configuration = talos_machine_secrets.cluster.client_configuration
  node                 = local.bootstrap_node.ip
  endpoint             = local.bootstrap_node.ip
}
