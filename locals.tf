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
      name         = "${s.name}-${format("%02d", i + 1)}"
      server_type  = s.server_type
      location     = s.location
      machine_type = "controlplane"
      firewall_id  = hcloud_firewall.control_planes.id
      private_ipv4 = cidrhost(
        hcloud_network_subnet.control_plane.ip_range, i + 101
      )
      config_patches = [yamlencode({
        machine = merge(
          local.machine_config,
          {
            nodeLabels = s.labels != null ? s.labels : {}
            nodeTaints = s.taints != null ? s.taints : {}
          }
        )
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
        firewall_id  = hcloud_firewall.workers.id
        private_ipv4 = cidrhost(
          hcloud_network_subnet.agent[[
            for i, v in var.agent_nodepools : i if v.name == s.name][0]
        ].ip_range, j + 101)
        volume_size = s.volume_size != null ? s.volume_size : 0
        config_patches = [yamlencode(
          {
            machine = merge(local.machine_config, {
              nodeLabels = s.labels != null ? s.labels : {}
              nodeTaints = s.taints != null ? s.taints : {}
              disks = s.volume_size == null ? [] : [
                {
                  device = "/dev/sdb"
                  partitions = [
                    {
                      mountpoint = "/var/mnt/longhorn"
                    }
                  ]
                }
              ]
            })
            cluster = local.config_patches["cluster_worker_config"]
          }
        )]
      }
    ]
  ])
  servers = concat(local.control_planes, local.agents)
}
