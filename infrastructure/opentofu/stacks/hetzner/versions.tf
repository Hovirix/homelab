terraform {
  required_version = ">= 1.11.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.69.0"
    }

    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
  }
}
