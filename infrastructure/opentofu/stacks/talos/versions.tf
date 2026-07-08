terraform {
  required_version = ">= 1.11.0"

  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.11.0"
    }
  }
}
