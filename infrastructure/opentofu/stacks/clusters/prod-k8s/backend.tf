variable "opentofu_state_encryption_passphrase" {
  type      = string
  sensitive = true
}

terraform {
  backend "s3" {
    bucket = "tf-state"
    key    = "prod/clusters/prod-k8s/terraform.tfstate"
    region = "auto"

    endpoints = {
      s3 = "https://2bcc2c0c19d1ad6037c19ed8fe4a0043.r2.cloudflarestorage.com"
    }

    use_path_style              = true
    use_lockfile                = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }

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
