module "homelab_tunnel" {
  source = "../../../modules/cloudflare/zt_tunnel"

  account_id = local.account_id
  name       = "homelab"
  config_src = "cloudflare"
  ingress    = local.tunnel_ingress
}
