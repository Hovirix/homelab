provider "sops" {}

provider "proxmox" {
  endpoint  = "https://pve1.home.hovirix.dev:8006/"
  api_token = data.sops_file.infrastructure.data["proxmox.api_token"]
  insecure  = true
}
