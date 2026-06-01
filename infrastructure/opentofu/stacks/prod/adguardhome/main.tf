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
  }
}

resource "adguard_rewrite" "records" {
  for_each = local.dns_records

  domain  = each.value.domain
  answer  = each.value.answer
  enabled = lookup(each.value, "enabled", true)
}
