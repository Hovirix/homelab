resource "local_sensitive_file" "talosconfig" {
  content         = data.talos_client_configuration.cluster.talos_config
  filename        = "${path.module}/../../../../../.artifacts/talos/${local.cluster_name}/talosconfig"
  file_permission = "0600"
}

resource "local_sensitive_file" "kubeconfig" {
  content         = talos_cluster_kubeconfig.cluster.kubeconfig_raw
  filename        = "${path.module}/../../../../../.artifacts/talos/${local.cluster_name}/kubeconfig"
  file_permission = "0600"
}
