terraform {
  required_version = ">= 1.11.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.97.0"
    }

    sops = {
      source  = "carlpett/sops"
      version = "1.3.0"
    }

    ct = {
      source  = "poseidon/ct"
      version = "0.14.0"
    }
  }
}
