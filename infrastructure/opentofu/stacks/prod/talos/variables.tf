variable "cluster" {
  type = object({
    name               = string
    endpoint           = string
    vip                = string
    interface          = string
    talos_version      = string
    kubernetes_version = string
    bootstrap_node     = string
  })

  default = {
    name               = "prod-k8s"
    endpoint           = "prod-k8s.home.hovirix.dev"
    vip                = "10.40.0.10"
    interface          = "eth0"
    talos_version      = "v1.13.3"
    kubernetes_version = "v1.35.4"
    bootstrap_node     = "cp1"
  }
}

variable "nodes" {
  type = map(object({
    hostname = string
    role     = string
  }))

  default = {
    cp1 = {
      hostname = "prod-k8s-cp-01.home.hovirix.dev"
      role     = "controlplane"
    }
    # cp2 = {
    #   hostname = "prod-k8s-cp-02.home.hovirix.dev"
    #   role     = "controlplane"
    # }
    # cp3 = {
    #   hostname = "prod-k8s-cp-03.home.hovirix.dev"
    #   role     = "controlplane"
    # }
  }
}
