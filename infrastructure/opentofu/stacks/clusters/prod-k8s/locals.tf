locals {
  cluster_name       = "prod-k8s"
  domain             = "home.hovirix.dev"
  cluster_hostname   = "${local.cluster_name}.${local.domain}"
  cluster_endpoint   = "https://${local.cluster_hostname}:6443"
  cluster_vip        = "10.40.0.10"
  network_interface  = "ens18"
  talos_version      = "v1.13.3"
  kubernetes_version = "v1.35.4"

  active_nodes        = { for name, node in local.nodes : name => node if node.enabled }
  controlplane_nodes  = { for name, node in local.active_nodes : name => node if node.machine_type == "controlplane" }
  controlplane        = local.controlplane_nodes["cp1"]
  bootstrap_node      = local.controlplane
  talos_api_endpoints = [for node in values(local.controlplane_nodes) : node.fqdn]

  cluster_dns_records = merge(
    {
      (local.cluster_name) = {
        domain = local.cluster_hostname
        answer = local.cluster_vip
      }
    },
    {
      for _, node in local.nodes : node.hostname => {
        domain = node.fqdn
        answer = node.ip
      }
    },
  )

  machine_patch = yamlencode({
    machine = {
      install = {
        disk = "/dev/vda"
      }

      certSANs = [for node in values(local.controlplane_nodes) : node.fqdn]

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
        certSANs = [
          local.cluster_hostname,
          local.cluster_vip,
        ]
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
