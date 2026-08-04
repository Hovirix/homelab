terraform {
  required_version = ">= 1.11.0"

  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "3.5.0"
    }

    proxmox = {
      source  = "bpg/proxmox"
      version = "0.111.1"
    }

    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
  }
}
