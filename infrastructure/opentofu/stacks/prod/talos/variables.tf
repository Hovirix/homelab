variable "cluster_name" {
  type    = string
  default = "prod-k8s"
}

variable "controlplane_vip" {
  type    = string
  default = "10.40.0.10"
}

variable "talos_version" {
  type    = string
  default = "v1.13.3"
}

variable "kubernetes_version" {
  type    = string
  default = "v1.35.4"
}

variable "controlplane" {
  type = object({
    endpoint  = string
    interface = string
  })

  default = {
    endpoint  = "prod-k8s-cp-01.home.hovirix.dev"
    interface = "eth0"
  }
}
