module "first_control_plane" {
  source              = "./host"
  name                = "${var.cluster_name}-${local.control_planes[0].name}"
  type                = local.control_planes[0].server_type
  location            = local.control_planes[0].location
  hcloud_firewall_ids = [hcloud_firewall.k3s.id]
  hcloud_network_id   = hcloud_network.k3s.id
  private_ipv4        = local.control_planes[0].private_ipv4
}
