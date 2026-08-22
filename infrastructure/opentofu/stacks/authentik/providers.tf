provider "sops" {}

provider "authentik" {
  url   = "https://authentik.hovirix.dev"
  token = data.sops_file.infrastructure.data["authentik.api_token"]
}
