data "sops_file" "proxmox" {
  source_file = "${path.module}/../../secrets/infrastructure/proxmox.yaml"
}
