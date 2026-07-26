terraform {
  required_version = ">= 1.11.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.6.2"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.11.0"
    }
  }
}
