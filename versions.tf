terraform {
  required_version = ">= 1.5.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.43.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.6.1"
    }
  }
}
