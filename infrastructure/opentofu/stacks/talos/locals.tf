locals {
  cluster_name       = "prod-k8s"
  cluster_domain     = "home.hovirix.dev"
  cluster_hostname   = "${local.cluster_name}.${local.cluster_domain}"
  cluster_endpoint   = "https://${local.cluster_hostname}:6443"
  cluster_vip        = "10.40.0.10"
  network_interface  = "ens18"
  talos_version      = "v1.13.3"
  kubernetes_version = "v1.35.4"

  nodes = {
    cp1 = {
      hostname = "prod-k8s-cp-01"
      ip       = "10.40.0.11"
    }
  }

  bootstrap_node = local.nodes.cp1

  machine_patch = yamlencode({
    machine = {
      install = {
        disk = "/dev/vda"
      }

      features = {
        hostDNS = {
          enabled              = true
          forwardKubeDNSToHost = true
        }
      }
    }

    cluster = {
      allowSchedulingOnControlPlanes = true

      network = {
        cni = {
          name = "none"
        }
      }

      proxy = {
        disabled = true
      }

      apiServer = {
        certSANs = concat(
          [
            local.cluster_hostname,
            local.cluster_vip,
          ],
          [for node in values(local.nodes) : node.hostname],
          [for node in values(local.nodes) : node.ip],
        )
      }
    }
  })

  dhcp_patch = yamlencode({
    apiVersion = "v1alpha1"
    kind       = "DHCPv4Config"
    name       = local.network_interface
  })

  vip_patch = yamlencode({
    apiVersion = "v1alpha1"
    kind       = "Layer2VIPConfig"
    name       = local.cluster_vip
    link       = local.network_interface
  })
}
