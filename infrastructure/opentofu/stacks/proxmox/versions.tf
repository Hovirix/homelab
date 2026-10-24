terraform {
  required_version = ">= 1.11.0"

  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "3.6.2"
    }

    proxmox = {
      source  = "bpg/proxmox"
      version = "0.118.0"
    }
  }
}
