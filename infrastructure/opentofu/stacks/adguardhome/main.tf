locals {
  dns_records = {
    pve = {
      domain = "pve.home.hovirix.dev"
      answer = "10.20.0.11"
    }

    truenas = {
      domain = "truenas.home.hovirix.dev"
      answer = "10.30.0.106"
    }

    home_wildcard = {
      domain = "*.hovirix.dev"
      answer = "10.40.0.101"
    }

    home_wildcard_2 = {
      domain = "*.hovirix.dev"
      answer = "10.40.0.102"
    }

    home_wildcard_3 = {
      domain = "*.hovirix.dev"
      answer = "10.40.0.103"
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
