variable "cluster_name" {
  type    = string
  default = "prod-k8s"
}

variable "cluster_endpoint" {
  type    = string
  default = "https://prod-k8s.home.hovirix.dev:6443"
}

variable "talos_endpoint" {
  type    = string
  default = "prod-k8s.home.hovirix.dev"
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

variable "nameservers" {
  type    = list(string)
  default = ["10.40.0.1"]
}

variable "controlplanes" {
  type = map(object({
    hostname  = string
    dns_name  = string
    ip        = string
    interface = string
  }))

  default = {
    cp1 = {
      hostname  = "prod-k8s-cp-01"
      dns_name  = "prod-k8s-cp-01.home.hovirix.dev"
      ip        = "10.40.0.11"
      interface = "eth0"
    }

    # cp2 = {
    #   hostname  = "prod-k8s-cp-02"
    #   dns_name  = "prod-k8s-cp-02.home.hovirix.dev"
    #   ip        = "10.40.0.12"
    #   interface = "eth0"
    # }

    # cp3 = {
    #   hostname  = "prod-k8s-cp-03"
    #   dns_name  = "prod-k8s-cp-03.home.hovirix.dev"
    #   ip        = "10.40.0.13"
    #   interface = "eth0"
    # }
  }
}
