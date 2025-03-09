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
  nodes = [
    for s in hcloud_server.servers : s.name
  ]
}

data "talos_machine_configuration" "this" {
  for_each           = { for m in local.servers : m.name => m }
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  machine_type       = each.value.machine_type
  cluster_endpoint   = local.cluster_internal_endpoint
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  docs               = false
  examples           = false
  config_patches     = each.value.init_config_patches
}

resource "talos_machine_configuration_apply" "this" {
  for_each                    = { for s in local.servers : s.name => s }
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[each.value.name].machine_configuration
  endpoint                    = local.cluster_endpoint
  node                        = "${var.cluster_name}-${each.key}"
  config_patches              = each.value.config_patches
  depends_on = [
    time_sleep.wait_for_volumes
  ]
}

resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = local.cluster_endpoint
  node                 = hcloud_server.servers[0].name
  depends_on = [
    talos_machine_configuration_apply.this
  ]
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = local.cluster_endpoint
  node                 = hcloud_server.servers[0].name
  depends_on = [
    talos_machine_bootstrap.this
  ]
}
