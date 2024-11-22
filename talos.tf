resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

locals {
  cluster_internal_host     = "cluster.local"
  cluster_internal_endpoint = "https://${local.cluster_internal_host}:6443"
  first_control_plane       = values(module.control_planes)[0]

}

data "talos_machine_configuration" "this" {
  for_each           = { for m in concat(local.control_planes, local.agents) : m.name => m }
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  machine_type       = each.value.machine_type
  cluster_endpoint   = local.cluster_internal_endpoint
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  docs               = false
  examples           = false
  config_patches     = m.config_patches
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints = [
    var.cluster_domain,
  ]
}

resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.first_control_plane.public_ipv4
  endpoint             = local.first_control_plane.public_ipv4
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.first_control_plane.public_ipv4
  depends_on = [
    talos_machine_bootstrap.this
  ]
}

# resource "talos_machine_configuration_apply" "this" {
#   client_configuration        = talos_machine_secrets.this.client_configuration
#   machine_configuration_input = data.talos_machine_configuration.this.machine_configuration
#   node                        = "10.5.0.2"
#   config_patches = [
#     yamlencode({
#       machine = {
#         install = {
#           disk = "/dev/sdd"
#         }
#       }
#     })
#   ]
# }
