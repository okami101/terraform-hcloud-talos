terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

module "talos" {
  source  = "hcloud-talos/talos/hcloud"
  version = "2.11.9"

  cluster_name     = "okami-talos"
  talos_version    = "v1.8.2"
  cluster_api_host = "talos.okami101.io"

  firewall_use_current_ip = true
  hcloud_token            = var.hcloud_token

  datacenter_name = "fsn1-dc14"

  control_plane_count       = 1
  control_plane_server_type = "cx22"

  # Pas de support de pool de serveurs pour les workers...
  worker_count       = 3
  worker_server_type = "cx22"
}
