terraform {
  required_version = ">= 1.11.0"

  required_providers {
    adguard = {
      source  = "gmichels/adguard"
      version = "1.7.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.9.0"
    }

    proxmox = {
      source  = "bpg/proxmox"
      version = "0.111.1"
    }

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
