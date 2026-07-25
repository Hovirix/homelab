locals {
  config        = yamldecode(file("${path.module}/config.yaml"))
  talos_secrets = yamldecode(data.sops_file.infrastructure.raw).talos

  machine_secrets = {
    certs = {
      etcd = {
        cert = local.talos_secrets.machine_secrets.certs.etcd.crt
        key  = local.talos_secrets.machine_secrets.certs.etcd.key
      }
      k8s = {
        cert = local.talos_secrets.machine_secrets.certs.k8s.crt
        key  = local.talos_secrets.machine_secrets.certs.k8s.key
      }
      k8s_aggregator = {
        cert = local.talos_secrets.machine_secrets.certs.k8saggregator.crt
        key  = local.talos_secrets.machine_secrets.certs.k8saggregator.key
      }
      k8s_serviceaccount = {
        key = local.talos_secrets.machine_secrets.certs.k8sserviceaccount.key
      }
      os = {
        cert = local.talos_secrets.machine_secrets.certs.os.crt
        key  = local.talos_secrets.machine_secrets.certs.os.key
      }
    }
    cluster = local.talos_secrets.machine_secrets.cluster
    secrets = {
      bootstrap_token             = local.talos_secrets.machine_secrets.secrets.bootstraptoken
      secretbox_encryption_secret = local.talos_secrets.machine_secrets.secrets.secretboxencryptionsecret
    }
    trustdinfo = {
      token = local.talos_secrets.machine_secrets.trustdinfo.token
    }
  }

  nodes = {
    for key, node in local.config.nodes : key => merge(node, {
      hostname = "${node.name}.${local.config.domain}"
    })
  }

  controlplane_nodes = {
    for name, node in local.nodes : name => node
    if node.role == "controlplane"
  }

  talos_endpoints = [
    for node in values(local.controlplane_nodes) : node.hostname
  ]

  talos_nodes = [
    for node in values(local.nodes) : node.hostname
  ]

  bootstrap_node = local.controlplane_nodes[local.config.cluster.bootstrap_node].hostname

  cluster_hostname = "${local.config.cluster.name}.${local.config.domain}"
  cluster_endpoint = "https://${local.cluster_hostname}:6443"

  talos_cert_sans = concat(
    [local.cluster_hostname],
    [for node in values(local.controlplane_nodes) : node.hostname]
  )

  controlplane_node_patches = {
    for name, node in local.controlplane_nodes : name => yamlencode({
      machine = {
        certSANs = local.talos_cert_sans

        network = {

          interfaces = [{
            interface = local.config.cluster.interface
            dhcp      = true

            vip = {
              ip = local.config.cluster.vip
            }
          }]
        }
      }

      cluster = {
        apiServer = {
          certSANs = local.talos_cert_sans
        }
      }
    })
  }
}
