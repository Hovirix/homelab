locals {
  talos_secrets = yamldecode(data.sops_file.infrastructure.raw).talos

  machine_secrets = {
    certs = {
      etcd = {
        cert = local.talos_secrets.certs.etcd.crt
        key  = local.talos_secrets.certs.etcd.key
      }
      k8s = {
        cert = local.talos_secrets.certs.k8s.crt
        key  = local.talos_secrets.certs.k8s.key
      }
      k8s_aggregator = {
        cert = local.talos_secrets.certs.k8saggregator.crt
        key  = local.talos_secrets.certs.k8saggregator.key
      }
      k8s_serviceaccount = {
        key = local.talos_secrets.certs.k8sserviceaccount.key
      }
      os = {
        cert = local.talos_secrets.certs.os.crt
        key  = local.talos_secrets.certs.os.key
      }
    }
    cluster = local.talos_secrets.cluster
    secrets = {
      bootstrap_token             = local.talos_secrets.secrets.bootstraptoken
      secretbox_encryption_secret = local.talos_secrets.secrets.secretboxencryptionsecret
    }
    trustdinfo = {
      token = local.talos_secrets.trustdinfo.token
    }
  }

  controlplane_nodes = {
    for name, node in var.nodes : name => node
    if node.role == "controlplane"
  }

  worker_nodes = {
    for name, node in var.nodes : name => node
    if node.role == "worker"
  }

  talos_endpoints = [
    for node in values(local.controlplane_nodes) : node.hostname
  ]

  talos_nodes = [
    for node in values(var.nodes) : node.hostname
  ]

  bootstrap_node = local.controlplane_nodes[var.cluster.bootstrap_node].hostname

  cluster_endpoint = "https://${var.cluster.endpoint}:6443"

  controlplane_node_patch = yamlencode({
    machine = {
      certSANs = [
        local.bootstrap_node
      ]

      network = {
        interfaces = [
          {
            interface = var.cluster.interface
            dhcp      = true

            vip = {
              ip = var.cluster.vip
            }
          }
        ]
      }
    }

    cluster = {
      apiServer = {
        certSANs = [
          var.cluster.endpoint
        ]
      }
    }
  })
}
