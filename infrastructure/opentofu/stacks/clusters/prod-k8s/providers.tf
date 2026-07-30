provider "sops" {}

provider "adguard" {
  host     = "10.10.0.1:3000"
  username = data.sops_file.infrastructure.data["adguardhome.username"]
  password = data.sops_file.infrastructure.data["adguardhome.password"]
  scheme   = "http"
  insecure = true
}

provider "proxmox" {
  insecure  = true
  endpoint  = "https://pve1.home.hovirix.dev:8006/"
  api_token = "opentofu@pve!opentofu=${data.sops_file.infrastructure.data["proxmox.api_token"]}"
}
