# Reuse the CLI's client identity and verified server certificate.
provider "incus" {
  default_remote = "incus"

  remote {
    name = "incus"
  }
}
