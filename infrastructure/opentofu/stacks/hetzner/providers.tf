provider "sops" {}

provider "hcloud" {
  token = data.sops_file.infrastructure.data["hetzner.api_token"]
}
