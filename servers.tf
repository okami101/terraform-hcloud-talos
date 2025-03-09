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

resource "hcloud_server" "servers" {
  for_each           = { for i, s in local.servers : s.name => s }
  name               = "${var.cluster_name}-${each.key}"
  server_type        = each.value.server_type
  location           = each.value.location
  image              = substr(each.value.server_type, 0, 3) == "cax" ? data.hcloud_image.talos_arm_snapshot.id : data.hcloud_image.talos_x86_snapshot.id
  placement_group_id = each.value.placement_group_id
  firewall_ids       = each.value.firewall_ids
  network {
    network_id = hcloud_network.talos.id
    ip         = each.value.private_ipv4
    alias_ips  = []
  }
  user_data = data.talos_machine_configuration.this[each.value.name].machine_configuration
  lifecycle {
    ignore_changes = [
      user_data,
      image
    ]
  }
}

resource "hcloud_volume" "volumes" {
  for_each  = { for i, s in local.servers : s.name => s if s.volume_size >= 10 }
  name      = "${var.cluster_name}-${each.key}"
  size      = each.value.volume_size
  server_id = hcloud_server.servers[each.key].id
  automount = true
  format    = "ext4"
}

resource "time_sleep" "wait_for_volumes" {
  depends_on = [hcloud_volume.volumes]

  create_duration = "10s"
}
