provider "sops" {}

provider "cloudflare" {
  api_token = data.sops_file.cloudflare.data["api_token"]
}
