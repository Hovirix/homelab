terraform {
  required_version = ">= 1.11.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.97.1"
    }

    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
  }
}
