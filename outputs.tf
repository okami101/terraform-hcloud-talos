output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "kubeconfig" {
  value = replace(
    talos_cluster_kubeconfig.this.kubeconfig_raw,
    local.cluster_internal_host, var.cluster_domain
  )
  sensitive = true
}
