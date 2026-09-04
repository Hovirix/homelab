terraform {
  required_version = ">= 1.11.0"

  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "3.6.1"
    }

    proxmox = {
      source  = "bpg/proxmox"
      version = "0.112.0"
    }

    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
  }
}
