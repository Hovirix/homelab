provider "sops" {}

provider "proxmox" {
  endpoint  = data.sops_file.proxmox.data["proxmox.endpoint"]
  api_token = data.sops_file.proxmox.data["proxmox.api_token"]
  insecure  = true
}
