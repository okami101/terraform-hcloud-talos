resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

locals {
  cluster_endpoint = "https://cluster.local:6443"
}

data "talos_machine_configuration" "this" {
  for_each           = { for machine in concat(local.control_planes, local.agents) : machine.name => machine }
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  machine_type       = each.value.machine_type
  cluster_endpoint   = local.cluster_endpoint
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  docs               = false
  examples           = false
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = var.talos_client_endpoints
}

resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = module.control_planes[0].public_ipv4
  endpoint             = module.control_planes[0].public_ipv4
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = module.control_planes[0].public_ipv4
  depends_on = [
    talos_machine_bootstrap.this
  ]
}
