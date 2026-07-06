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

  controlplane_keys      = sort(keys(var.controlplanes))
  controlplanes          = [for key in local.controlplane_keys : var.controlplanes[key]]
  bootstrap_node         = local.controlplanes[0].dns_name
  controlplane_dns_names = [for node in local.controlplanes : node.dns_name]

  node_patches = {
    for key, node in var.controlplanes : key => yamlencode({
      machine = {
        network = {
          interfaces = [
            {
              interface = node.interface
              dhcp      = true
              vip = {
                ip = var.controlplane_vip
              }
            },
          ]
        }
      }
    })
  }
}
