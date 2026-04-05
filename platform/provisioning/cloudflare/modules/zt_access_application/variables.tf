variable "account_id" {
  type = string
}

variable "name" {
  type = string
}

variable "hostname" {
  type = string
}

variable "type" {
  type    = string
  default = "self_hosted"

  validation {
    condition     = var.type == "self_hosted"
    error_message = "This module currently supports only self_hosted applications."
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
