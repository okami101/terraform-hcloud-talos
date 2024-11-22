locals {
  machine_config = {
    install = {
      image = "ghcr.io/siderolabs/installer:${var.talos_version}"
    }
    certSANs = var.talos_client_endpoints
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
  common_cluster_config = {
    network = {
      cni = {
        name = "none"
      }
    }
  }

  config_patches = {
    controlplane = {
      machine = local.machine_config
      cluster = merge(local.common_cluster_config, {
        allowSchedulingOnControlPlanes = false
        proxy = {
          disabled = true
        }
        apiServer = {
          certSANs = var.talos_client_endpoints
        }
        controllerManager = {
          extraArgs = {
            "cloud-provider" = "external"
            "bind-address"   = "0.0.0.0"
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
      })
    }

    worker = {
      machine = local.machine_config
      cluster = local.common_cluster_config
    }
  }
}
