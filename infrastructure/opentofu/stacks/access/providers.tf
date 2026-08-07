provider "sops" {}

provider "authentik" {
  url   = "https://authentik.home.hovirix.dev"
  token = data.sops_file.identity.data["authentik.token"]
}

provider "cloudflare" {
  api_token = data.sops_file.infrastructure.data["cloudflare.api_token"]
}
