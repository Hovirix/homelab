resource "adguard_rewrite" "records" {
  for_each = local.cluster_dns_records

  domain  = each.value.domain
  answer  = each.value.answer
  enabled = lookup(each.value, "enabled", true)

  depends_on = [
    proxmox_virtual_environment_vm.controlplane,
  ]
}
