locals {
  fcos_nodes = {
    swarm-01 = {
      ignition_file = "swarm-01.ign"
      cpu_cores     = 4
      memory_mb     = 10240
      boot_disk_gb  = 64
    }
    swarm-02 = {
      ignition_file = "swarm-02.ign"
      cpu_cores     = 4
      memory_mb     = 10240
      boot_disk_gb  = 64
    }
    swarm-03 = {
      ignition_file = "swarm-03.ign"
      cpu_cores     = 4
      memory_mb     = 10240
      boot_disk_gb  = 64
    }
  }
}
