resource "proxmox_virtual_environment_download_file" "fedora_cloud_image" {
  content_type       = "import"
  datastore_id       = "local"
  node_name          = "compute-01"
  file_name          = "Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2"
  url                = "https://download.fedoraproject.org/pub/fedora/linux/releases/43/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2"
  checksum           = "846574c8a97cd2d8dc1f231062d73107cc85cbbbda56335e264a46e3a6c8ab2f"
  checksum_algorithm = "sha256"
}

resource "proxmox_virtual_environment_download_file" "fedora_cloud_image_infra" {
  content_type       = "import"
  datastore_id       = "local"
  node_name          = "infra-01"
  file_name          = "Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2"
  url                = "https://download.fedoraproject.org/pub/fedora/linux/releases/43/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2"
  checksum           = "846574c8a97cd2d8dc1f231062d73107cc85cbbbda56335e264a46e3a6c8ab2f"
  checksum_algorithm = "sha256"
}
