variable "account_id" {
  type = string
}

variable "name" {
  type = string
}

variable "config_src" {
  type    = string
  default = "cloudflare"

  validation {
    condition     = contains(["cloudflare", "local"], var.config_src)
    error_message = "config_src must be either \"cloudflare\" or \"local\"."
  }
}

variable "ingress" {
  type = list(object({
    service  = string
    hostname = optional(string)
    path     = optional(string)
    origin_request = optional(object({
      connect_timeout          = optional(string)
      disable_chunked_encoding = optional(bool)
      http2_origin             = optional(bool)
      http_host_header         = optional(string)
      no_happy_eyeballs        = optional(bool)
      no_tls_verify            = optional(bool)
      proxy_address            = optional(string)
      proxy_port               = optional(number)
      tcp_keep_alive           = optional(string)
      tls_timeout              = optional(string)
    }))
  }))
}
