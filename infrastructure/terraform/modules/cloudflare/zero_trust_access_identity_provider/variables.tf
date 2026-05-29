variable "account_id" {
  type = string
}

variable "name" {
  type = string
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type      = string
  sensitive = true
}

variable "auth_url" {
  type = string
}

variable "token_url" {
  type = string
}

variable "certs_url" {
  type = string
}

variable "scopes" {
  type    = list(string)
  default = ["openid", "profile", "email"]
}

variable "claims" {
  type    = list(string)
  default = []
}

variable "pkce_enabled" {
  type    = bool
  default = true
}
