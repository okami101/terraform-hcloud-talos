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

  cluster_name  = "okami-talos"
  talos_version = "v1.8.2"

  firewall_use_current_ip = true
  hcloud_token            = var.hcloud_token

  control_plane_count       = 1
  control_plane_server_type = "cx22"

  datacenter_name = "fsn1-dc14"
}
