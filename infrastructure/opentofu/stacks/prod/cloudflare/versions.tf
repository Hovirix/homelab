terraform {
  required_version = ">= 1.11.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.19.1"
    }

    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
  }
}
