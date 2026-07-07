variable "domain" {
  type    = string
  default = "home.hovirix.dev"
}

variable "cluster" {
  type = object({
    name               = string
    vip                = string
    interface          = string
    talos_version      = string
    kubernetes_version = string
    bootstrap_node     = string
  })

  default = {
    name               = "prod-k8s"
    vip                = "10.40.0.10"
    interface          = "ens18"
    talos_version      = "v1.13.3"
    kubernetes_version = "v1.35.4"
    bootstrap_node     = "cp1"
  }
}

variable "nodes" {
  type = map(object({
    name = string
    role = string
  }))

  default = {
    cp1 = {
      name = "prod-k8s-cp-01"
      role = "controlplane"
    }
    # cp2 = {
    #   name = "prod-k8s-cp-02"
    #   role = "controlplane"
    # }
    # cp3 = {
    #   name = "prod-k8s-cp-03"
    #   role = "controlplane"
    # }
  }
}
