locals {
  dns_records = {
    pve1 = {
      domain = "pve1.home.hovirix.dev"
      answer = "10.20.0.11"
    }

    pve2 = {
      domain = "pve2.home.hovirix.dev"
      answer = "10.20.0.12"
    }

    pve3 = {
      domain = "pve3.home.hovirix.dev"
      answer = "10.20.0.13"
    }

    truenas = {
      domain = "truenas.home.hovirix.dev"
      answer = "10.30.0.106"
    }

    home_wildcard = {
      domain = "*.home.hovirix.dev"
      answer = "10.40.0.101"
    }

    "swarm-01" = {
      domain = "swarm-01.home.hovirix.dev"
      answer = "10.40.0.101"
    }

    "swarm-02" = {
      domain = "swarm-02.home.hovirix.dev"
      answer = "10.40.0.102"
    }

    "swarm-03" = {
      domain = "swarm-03.home.hovirix.dev"
      answer = "10.40.0.103"
    }
  }
}

resource "adguard_rewrite" "records" {
  for_each = local.dns_records

  domain  = each.value.domain
  answer  = each.value.answer
  enabled = lookup(each.value, "enabled", true)
}
