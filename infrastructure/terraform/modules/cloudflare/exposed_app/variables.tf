variable "account_id" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "name" {
  type = string
}

variable "dns_name" {
  type    = string
  default = null
}

variable "hostname" {
  type = string
}

variable "service" {
  type = string
}

variable "tunnel_cname" {
  type = string
}

variable "type" {
  type    = string
  default = "self_hosted"

  validation {
    condition     = contains(["self_hosted", "saas", "ssh", "vnc", "app_launcher", "warp", "biso", "bookmark", "dash_sso", "infrastructure", "rdp", "mcp", "mcp_portal", "proxy_endpoint"], var.type)
    error_message = "type must be a valid Cloudflare Access application type."
  }
}

variable "allowed_idps" {
  type    = list(string)
  default = []
}

variable "session_duration" {
  type    = string
  default = "24h"
}

variable "policy_ids" {
  type    = list(string)
  default = []
}
