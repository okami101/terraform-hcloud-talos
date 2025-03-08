packer {
  required_plugins {
    hcloud = {
      source  = "github.com/hetznercloud/hcloud"
      version = "~> 1"
    }
  }
}

variable "hcloud_token" {
  type      = string
  default   = env("HCLOUD_TOKEN")
  sensitive = true
}

variable "schematic_id" {
  type    = string
  default = "e76f17a9dab014eaf29af23cfb5eb98cd6fee7d7ba07ac6779238f12385fbb0b"
}

variable "talos_version" {
  type    = string
  default = "v1.9.4"
}

variable "arch" {
  type    = string
}

variable "server_location" {
  type    = string
  default = "nbg1"
}

locals {
  server_types = {
    amd64 = "cx22"
    arm64 = "cax11"
  }
  image = "https://factory.talos.dev/image/${var.schematic_id}/${var.talos_version}/hcloud-${var.arch}.raw.xz"
}

source "hcloud" "talos" {
  rescue       = "linux64"
  image        = "debian-12"
  location     = var.server_location
  server_type  = local.server_types[var.arch]
  ssh_username = "root"

  snapshot_name   = "talos system disk - ${var.arch} - ${var.talos_version}"
  snapshot_labels = {
    type    = "infra",
    os      = "talos",
    version = var.talos_version,
    arch    = var.arch,
  }
  token = var.hcloud_token
}

build {
  sources = ["source.hcloud.talos"]

  provisioner "shell" {
    inline = [
      "apt-get install -y wget",
      "wget -O /tmp/talos.raw.xz ${local.image}",
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync",
    ]
  }
}
