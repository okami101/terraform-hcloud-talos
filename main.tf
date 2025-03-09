locals {
  network_ipv4_subnets = [
    for index in range(256) : cidrsubnet(var.network_ipv4_cidr, 8, index)
  ]
  firewall_kube_api_source = var.firewall_kube_api_source == null ? [] : [
    {
      description = "Allow Incoming Requests to Kube API Server"
      direction   = "in"
      protocol    = "tcp"
      port        = "6443"
      source_ips  = var.firewall_kube_api_source
    },
  ]
  firewall_talos_api_source = var.firewall_talos_api_source == null ? [] : [
    {
      description = "Allow Incoming Talos API Traffic"
      direction   = "in"
      protocol    = "tcp"
      port        = "50000"
      source_ips  = var.firewall_talos_api_source
    }
  ]
}

resource "hcloud_network" "talos" {
  name     = var.cluster_name
  ip_range = var.network_ipv4_cidr
}

resource "hcloud_network_subnet" "control_plane" {
  network_id   = hcloud_network.talos.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = local.network_ipv4_subnets[255]
}

resource "hcloud_network_subnet" "agent" {
  count        = length(var.agent_nodepools)
  network_id   = hcloud_network.talos.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = local.network_ipv4_subnets[count.index]
}

resource "hcloud_firewall" "talos_api" {
  name = "${var.cluster_name}-talos-api"

  dynamic "rule" {
    for_each = local.firewall_talos_api_source
    content {
      description = rule.value.description
      direction   = rule.value.direction
      protocol    = rule.value.protocol
      port        = rule.value.port
      source_ips  = rule.value.source_ips
    }
  }
}

resource "hcloud_firewall" "kube_api" {
  name = "${var.cluster_name}-kube-api"

  dynamic "rule" {
    for_each = local.firewall_kube_api_source
    content {
      description = rule.value.description
      direction   = rule.value.direction
      protocol    = rule.value.protocol
      port        = rule.value.port
      source_ips  = rule.value.source_ips
    }
  }
}

resource "hcloud_placement_group" "talos" {
  for_each = { for pg in concat([
    for s in var.control_planes : s.placement_group if s.placement_group != null
    ], [
    for s in var.agent_nodepools : s.placement_group if s.placement_group != null
  ]) : pg => pg }
  name = "${var.cluster_name}-${each.value}"
  type = "spread"
}
