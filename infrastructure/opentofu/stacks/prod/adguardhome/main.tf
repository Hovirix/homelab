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

    prod-k8s-cp-01 = {
      domain = "prod-k8s-cp-01.home.hovirix.dev"
      answer = "10.40.0.1"
    }

    prod-k8s-cp-02 = {
      domain = "prod-k8s-cp-02.home.hovirix.dev"
      answer = "10.40.0.2"
    }

    prod-k8s-cp-03 = {
      domain = "prod-k8s-cp-03.home.hovirix.dev"
      answer = "10.40.0.3"
    }
  }
}

resource "adguard_rewrite" "records" {
  for_each = local.dns_records

  domain  = each.value.domain
  answer  = each.value.answer
  enabled = lookup(each.value, "enabled", true)
}
