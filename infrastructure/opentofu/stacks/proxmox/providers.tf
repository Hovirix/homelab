provider "proxmox" {
  endpoint = "https://pve.home.hovirix.dev:8006/"
  ssh {
    agent    = true
    username = "root"
  }
}
