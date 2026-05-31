terraform {
  required_version = ">= 1.11.0"

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.12.1"
    }

    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
  }
}
