variable "account_id" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "domain" {
  type = string
}

variable "tunnel" {
  type = object({
    name       = string
    config_src = optional(string, "cloudflare")
  })
}

variable "identity_provider" {
  type = object({
    name          = string
    client_id     = string
    client_secret = string
    auth_url      = string
    token_url     = string
    certs_url     = string
    scopes        = optional(list(string), ["openid", "profile", "email"])
    claims        = optional(list(string), ["groups"])
    pkce_enabled  = optional(bool, true)
  })
}

variable "access_policies" {
  type = map(object({
    group             = string
    allowed_countries = optional(list(string), [])
  }))

  validation {
    condition = alltrue(flatten([
      for policy in values(var.access_policies) : [
        for country in policy.allowed_countries : can(regex("^[A-Z]{2}$", country))
      ]
    ]))
    error_message = "Access policy allowed_countries entries must be uppercase ISO 3166-1 alpha-2 country codes."
  }
}

variable "applications" {
  type = map(object({
    upstream         = string
    access_policy    = string
    session_duration = optional(string, "24h")
  }))

  validation {
    condition = alltrue([
      for name in keys(var.applications) : can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", name))
    ])
    error_message = "Application names must be DNS-safe labels."
  }

  validation {
    condition = alltrue([
      for app in values(var.applications) : can(regex("^(http|https|tcp|ssh|rdp|unix|unix\\+tls|smb)://", app.upstream))
    ])
    error_message = "Application upstream values must start with a cloudflared-supported service scheme."
  }
}
