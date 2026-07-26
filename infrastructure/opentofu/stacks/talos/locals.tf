locals {
  cluster = {
    name               = "prod-k8s"
    domain             = "home.hovirix.dev"
    vip                = "10.40.0.10"
    interface          = "ens18"
    talos_version      = "v1.13.3"
    kubernetes_version = "v1.35.4"
    bootstrap_node     = "cp1"
  }

  nodes = {
    cp1 = {
      name    = "prod-k8s-cp-01"
      role    = "controlplane"
      address = "10.40.0.11/24"
    }
  }

  cluster_hostname = "${local.cluster.name}.${local.cluster.domain}"
  cluster_endpoint = "https://${local.cluster_hostname}:6443"

  resolved_nodes = {
    for key, node in local.nodes : key => merge(node, {
      hostname = "${node.name}.${local.cluster.domain}"
      ip       = split("/", node.address)[0]
    })
  }

  controlplane_nodes = {
    for key, node in local.resolved_nodes : key => node
    if node.role == "controlplane"
  }

  talos_endpoints = [
    for node in values(local.controlplane_nodes) : node.hostname
  ]

  talos_nodes = [
    for node in values(local.resolved_nodes) : node.hostname
  ]

  bootstrap_node = local.controlplane_nodes[
    local.cluster.bootstrap_node
  ]

  talos_api_sans = [
    for node in values(local.controlplane_nodes) : node.hostname
  ]

  kubernetes_api_sans = concat(
    [local.cluster_hostname, local.cluster.vip],
    [for node in values(local.controlplane_nodes) : node.hostname],
  )

  controlplane_node_patches = {
    for key, node in local.controlplane_nodes : key => yamlencode({
      machine = {
        certSANs = local.talos_api_sans

        network = {
          interfaces = [{
            interface = local.cluster.interface
            dhcp      = true

            vip = {
              ip = local.cluster.vip
            }
          }]
        }
      }

      cluster = {
        apiServer = {
          certSANs = local.kubernetes_api_sans
        }
      }
    })
  }
}
