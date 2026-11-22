resource "incus_instance" "fcos" {
  for_each = local.fcos_nodes

  name     = each.key
  type     = "virtual-machine"
  image    = incus_image.fcos.fingerprint
  profiles = []

  config = {
    "boot.autostart"         = "true"
    "limits.cpu"             = tostring(each.value.cpu_cores)
    "limits.memory"          = "${each.value.memory_mb}MiB"
    "cloud-init.vendor-data" = terraform_data.ignition[each.key].output
  }

  device {
    name = "config"
    type = "disk"
    properties = {
      source = "cloud-init:config"
    }
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      pool = "local"
      path = "/"
      size = "${each.value.boot_disk_gb}GiB"
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      nictype = "bridged"
      parent  = "uplink"
      vlan    = "30"
    }
  }

  device {
    name = "data"
    type = "disk"
    properties = {
      pool     = incus_storage_volume.swarm.pool
      source   = incus_storage_volume.swarm.name
      path     = "/var/mnt/swarm"
      "io.bus" = "virtiofs"
    }
  }
}
