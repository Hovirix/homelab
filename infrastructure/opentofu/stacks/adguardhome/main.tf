locals {
  dns_records = {
    pve = {
      domain = "pve.home.hovirix.dev"
      answer = "10.20.0.11"
    }

    # Ingress VIP floated by keepalived VRRP across the Swarm nodes.
    # Reserve 10.30.0.100 outside the DHCP range; keepalived assigns it to a node passing its local ingress check.
    home_ingress = {
      domain = "*.hovirix.dev"
      answer = "10.30.0.100"
    }

    "swarm-01" = {
      domain = "swarm-01.home.hovirix.dev"
      answer = "10.30.0.101"
    }

    "swarm-02" = {
      domain = "swarm-02.home.hovirix.dev"
      answer = "10.30.0.102"
    }

    "swarm-03" = {
      domain = "swarm-03.home.hovirix.dev"
      answer = "10.30.0.103"
    }
  }
}

resource "adguard_rewrite" "records" {
  for_each = local.dns_records

  domain = each.value.domain
  answer = each.value.answer
}
