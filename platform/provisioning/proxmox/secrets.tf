data "sops_file" "proxmox" {
  source_file = "${path.module}/../../security/secrets/infrastructure/proxmox.sops.yaml"
}
