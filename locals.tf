locals {
  kupe_api_server_url = "https://${local.control_planes[0].private_ipv4}:6443"
  control_planes = [
    for i, s in var.control_planes : {
      name         = "${s.name}-${format("%02d", i + 1)}"
      server_type  = s.server_type
      location     = s.location
      machine_type = "controlplane"
      private_ipv4 = cidrhost(
        hcloud_network_subnet.control_plane.ip_range, i + 101
      )
      labels = s.labels != null ? s.labels : {}
      taints = s.taints != null ? s.taints : {}
    }
  ]
  agents = flatten([
    for i, s in var.agent_nodepools : [
      for j in range(s.count) : {
        name         = "${s.name}-${format("%02d", j + 1)}"
        server_type  = s.server_type
        location     = s.location
        machine_type = "worker"
        private_ipv4 = cidrhost(
          hcloud_network_subnet.agent[[
            for i, v in var.agent_nodepools : i if v.name == s.name][0]
        ].ip_range, j + 101)
        labels      = s.labels != null ? s.labels : {}
        taints      = s.taints != null ? s.taints : {}
        volume_size = s.volume_size != null ? s.volume_size : 0
      }
    ]
  ])
}
