terraform {
  required_version = ">= 1.11.0"

  required_providers {
    adguard = {
      source  = "gmichels/adguard"
      version = "1.7.0"
    }

    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
  }
}
