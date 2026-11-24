terraform {
  required_version = ">= 1.11.0"

  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "1.2.1"
    }
  }
}
