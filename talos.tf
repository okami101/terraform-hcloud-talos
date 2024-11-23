resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

locals {
  cluster_internal_host     = "cluster.local"
  cluster_internal_endpoint = "https://${local.cluster_internal_host}:6443"
  cluster_endpoint          = var.talos_endpoint != null ? var.talos_endpoint : values(hcloud_server.servers)[0].ipv4_address
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints = [
    var.cluster_domain,
  ]
}

data "talos_machine_configuration" "this" {
  for_each           = { for m in local.servers : m.name => m }
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  machine_type       = each.value.machine_type
  cluster_endpoint   = local.cluster_internal_endpoint
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  docs               = false
  examples           = false
  config_patches     = each.value.config_patches
}

resource "talos_machine_configuration_apply" "this" {
  for_each                    = { for m in local.servers : m.name => m }
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[each.value.name].machine_configuration
  node                        = each.value.private_ipv4
  endpoint                    = local.cluster_endpoint
  depends_on = [
    hcloud_server.servers,
    hcloud_volume.volumes,
  ]
}

resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.cluster_endpoint
  depends_on = [
    talos_machine_configuration_apply.this
  ]
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.cluster_endpoint
  depends_on = [
    talos_machine_bootstrap.this
  ]
}
