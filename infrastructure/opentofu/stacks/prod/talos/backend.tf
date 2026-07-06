variable "opentofu_state_encryption_passphrase" {
  type      = string
  sensitive = true
}

terraform {
  encryption {
    key_provider "pbkdf2" "state" {
      passphrase    = var.opentofu_state_encryption_passphrase
      key_length    = 32
      iterations    = 600000
      hash_function = "sha512"
    }

    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.state
    }

    state {
      enforced = true
      method   = method.aes_gcm.state
    }

    plan {
      enforced = true
      method   = method.aes_gcm.state
    }
  }
}
