provider "sops" {}

provider "cloudflare" {
  api_token = data.sops_file.infrastructure.data["cloudflare.api_token"]
}
