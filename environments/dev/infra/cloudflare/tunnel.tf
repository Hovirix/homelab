module "homelab_tunnel" {
  source = "../../../../platform/provisioning/cloudflare/modules/zt_tunnel"

  account_id = local.account_id
  name       = "homelab"
  config_src = "cloudflare"
  ingress    = local.tunnel_ingress
}
