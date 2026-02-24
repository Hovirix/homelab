provider "sops" {}

provider "authentik" {
  url   = "https://idp.nemnix.site"
  token = data.sops_file.authentik_token.data["authentik_token"]
}
