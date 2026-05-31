variable "name" {
  type = string
}

variable "slug" {
  type = string
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type      = string
  sensitive = true
}

variable "redirect_uris" {
  type = list(string)
}
