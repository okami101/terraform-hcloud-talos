resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_machine_configuration" "this" {
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  machine_type       = "controlplane"
  cluster_endpoint   = "https://cluster.local:6443"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  docs               = false
  examples           = false
}
