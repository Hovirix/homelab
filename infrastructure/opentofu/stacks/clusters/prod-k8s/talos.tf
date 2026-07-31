resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = [
          "siderolabs/qemu-guest-agent",
        ]
      }
    }
  })
}

resource "talos_machine_secrets" "cluster" {
  talos_version = local.talos_version

  lifecycle {
    prevent_destroy = true
  }
}

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
  for_each = local.controlplane_nodes

  depends_on = [
    adguard_rewrite.records,
  ]

  node                        = each.value.fqdn
  endpoint                    = each.value.fqdn
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

  node                 = local.bootstrap_node.fqdn
  endpoint             = local.bootstrap_node.fqdn
  client_configuration = talos_machine_secrets.cluster.client_configuration
}

data "talos_client_configuration" "cluster" {
  depends_on = [
    talos_machine_bootstrap.cluster,
  ]

  cluster_name         = local.cluster_name
  client_configuration = talos_machine_secrets.cluster.client_configuration
  endpoints            = local.talos_api_endpoints
  nodes                = local.talos_api_endpoints
}

resource "talos_cluster_kubeconfig" "cluster" {
  depends_on = [
    talos_machine_bootstrap.cluster,
  ]

  client_configuration = talos_machine_secrets.cluster.client_configuration
  node                 = local.bootstrap_node.fqdn
  endpoint             = local.bootstrap_node.fqdn
}
