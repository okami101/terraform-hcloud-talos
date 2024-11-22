module "control_planes" {
  for_each            = { for i, s in local.control_planes : s.name => s }
  source              = "./host"
  name                = "${var.cluster_name}-${each.key}"
  talos_version       = var.talos_version
  type                = each.value.server_type
  location            = each.value.location
  hcloud_firewall_ids = [hcloud_firewall.kube.id]
  hcloud_network_id   = hcloud_network.kube.id
  private_ipv4        = each.value.private_ipv4
  user_data           = data.talos_machine_configuration.this[each.value.name].machine_configuration
}
