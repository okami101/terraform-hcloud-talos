locals {
  machine_config = {
    install = {
      image = "ghcr.io/siderolabs/installer:${var.talos_version}"
    }
    certSANs = [
      var.cluster_domain
    ]
    kubelet = {
      extraArgs = {
        "cloud-provider"             = "external"
        "rotate-server-certificates" = true
      }
    }
    network = {
      kubespan = {
        enabled                     = true
        advertiseKubernetesNetworks = false
        mtu                         = 1370
      }
    }
    sysctls = {
      "net.core.somaxconn"          = "65535"
      "net.core.netdev_max_backlog" = "4096"
    },
    features = {
      hostDNS = {
        enabled              = true
        forwardKubeDNSToHost = true
        resolveMemberNames   = true
      }
    }
  }

  cluster_common_config = {
    network = {
      cni = {
        name = "none"
      }
    }
  }

  config_patches = {

    cluster_worker_config = local.cluster_common_config
    cluster_controlplane_config = merge(local.cluster_common_config, {
      proxy = {
        disabled = true
      }
      apiServer = {
        certSANs = [
          var.cluster_domain
        ]
      }
      controllerManager = {
        extraArgs = {
          "bind-address" = "0.0.0.0"
        }
      }
      etcd = {
        extraArgs = {
          "listen-metrics-urls" = "http://0.0.0.0:2381"
        }
      }
      scheduler = {
        extraArgs = {
          "bind-address" = "0.0.0.0"
        }
      }
      externalCloudProvider = {
        enabled = true
      }
    })
  }
  control_planes = [
    for i, s in var.control_planes : {
      name         = s.name
      server_type  = s.server_type
      location     = s.location
      machine_type = "controlplane"
      firewall_ids = [hcloud_firewall.talos_api.id, hcloud_firewall.kube_api.id]
      private_ipv4 = cidrhost(
        hcloud_network_subnet.control_plane.ip_range, i + 101
      )
      placement_group_id = s.placement_group != null ? hcloud_placement_group.talos[s.placement_group].id : null
      volume_size        = 0
      config_patches     = s.config_patches != null ? s.config_patches : []
      init_config_patches = [yamlencode({
        machine = local.machine_config
        cluster = local.config_patches["cluster_controlplane_config"]
      })]
    }
  ]
  agents = flatten([
    for i, s in var.agent_nodepools : [
      for j in range(s.count) : {
        name         = "${s.name}-${format("%02d", j + 1)}"
        server_type  = s.server_type
        location     = s.location
        machine_type = "worker"
        firewall_ids = [hcloud_firewall.talos_api.id]
        private_ipv4 = cidrhost(
          hcloud_network_subnet.agent[[
            for i, v in var.agent_nodepools : i if v.name == s.name][0]
        ].ip_range, j + 101)
        placement_group_id = s.placement_group != null ? hcloud_placement_group.talos[s.placement_group].id : null
        volume_size        = s.volume_size != null ? s.volume_size : 0
        config_patches     = s.config_patches != null ? s.config_patches : []
        init_config_patches = [yamlencode(
          {
            machine = local.machine_config
            cluster = local.config_patches["cluster_worker_config"]
          }
        )]
      }
    ]
  ])
  servers = concat(local.control_planes, local.agents)
}
