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

  kubernetes_endpoint = "https://${var.controlplane.endpoint}:6443"

  node_patch = yamlencode({
    machine = {
      network = {
        interfaces = [
          {
            interface = var.controlplane.interface
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
