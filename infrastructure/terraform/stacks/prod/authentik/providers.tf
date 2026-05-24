provider "sops" {}

provider "authentik" {
  url   = "https://authentik.home.hovirix.dev"
  token = data.sops_file.authentik_token.data["authentik_token"]
}
