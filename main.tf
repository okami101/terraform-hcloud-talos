locals {
  network_ipv4_subnets = [
    for index in range(256) : cidrsubnet(var.network_ipv4_cidr, 8, index)
  ]
  firewall_common_rules = [
    {
      description = "Allow Incoming ICMP Ping Requests"
      direction   = "in"
      protocol    = "icmp"
      port        = ""
      source_ips  = ["0.0.0.0/0", "::/0"]
    }
  ]
}

resource "hcloud_network" "kube" {
  name     = var.cluster_name
  ip_range = var.network_ipv4_cidr
}

resource "hcloud_network_subnet" "control_plane" {
  network_id   = hcloud_network.kube.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = local.network_ipv4_subnets[255]
}

resource "hcloud_network_subnet" "agent" {
  count        = length(var.agent_nodepools)
  network_id   = hcloud_network.kube.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = local.network_ipv4_subnets[count.index]
}

resource "hcloud_firewall" "kube" {
  name = "${var.cluster_name}-kube"

  dynamic "rule" {
    for_each = concat(
      local.firewall_common_rules,
      var.firewall_kube_api_source == null ? [] : [
        {
          description = "Allow Incoming Requests to Kube API Server"
          direction   = "in"
          protocol    = "tcp"
          port        = "6443"
          source_ips  = var.firewall_kube_api_source
        },
      ],
    )
    content {
      description = rule.value.description
      direction   = rule.value.direction
      protocol    = rule.value.protocol
      port        = rule.value.port
      source_ips  = rule.value.source_ips
    }
  }
}

resource "hcloud_firewall" "talos" {
  name = "${var.cluster_name}-talos"

  dynamic "rule" {
    for_each = concat(
      local.firewall_common_rules,
      var.firewall_talos_api_source == null ? [] : [
        {
          description = "Allow Incoming Talos API Traffic"
          direction   = "in"
          protocol    = "tcp"
          port        = "50000"
          source_ips  = var.firewall_talos_api_source
        },
      ]
    )
    content {
      description = rule.value.description
      direction   = rule.value.direction
      protocol    = rule.value.protocol
      port        = rule.value.port
      source_ips  = rule.value.source_ips
    }
  }
}
