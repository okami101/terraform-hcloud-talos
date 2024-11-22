data "hcloud_image" "talos_x86_snapshot" {
  with_selector     = "version=${var.talos_version}"
  with_architecture = "x86"
  most_recent       = true
}

data "hcloud_image" "talos_arm_snapshot" {
  with_selector     = "version=${var.talos_version}"
  with_architecture = "arm"
  most_recent       = true
}

resource "hcloud_server" "server" {
  name         = var.name
  server_type  = var.type
  location     = var.location
  image        = substr(var.type, 0, 3) == "cax" ? data.hcloud_image.talos_arm_snapshot.id : data.hcloud_image.talos_x86_snapshot.id
  firewall_ids = var.hcloud_firewall_ids
  network {
    network_id = var.hcloud_network_id
    ip         = var.private_ipv4
    alias_ips  = []
  }
  user_data = var.user_data
  lifecycle {
    ignore_changes = [
      user_data,
      image
    ]
  }
}

resource "hcloud_volume" "volumes" {
  for_each  = { for i, v in var.hcloud_volumes : i => v if v.size >= 10 }
  name      = each.value.name
  size      = each.value.size
  server_id = hcloud_server.server.id
  automount = true
  format    = "ext4"
}
