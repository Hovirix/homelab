variable "account_id" {
  type = string
}

variable "name" {
  type = string
}

variable "decision" {
  type    = string
  default = "allow"

  validation {
    condition     = contains(["allow", "deny", "non_identity", "bypass"], var.decision)
    error_message = "decision must be one of: allow, deny, non_identity, bypass."
  }
}

variable "include" {
  type    = list(any)
  default = []
}

variable "require" {
  type    = list(any)
  default = []
}

variable "exclude" {
  type    = list(any)
  default = []
}

variable "session_duration" {
  type    = string
  default = null
}
