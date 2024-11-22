resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

locals {
  cluster_internal_host     = "cluster.local"
  cluster_internal_endpoint = "https://${local.cluster_internal_host}:6443"
  first_control_plane       = values(module.control_planes)[0]
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
    provisioning = {
      diskSelector = {
        match = "disk.model == 'Volume'"
      }
      grow = true
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
}

data "talos_machine_configuration" "this" {
  for_each           = { for m in concat(local.control_planes, local.agents) : m.name => m }
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  machine_type       = each.value.machine_type
  cluster_endpoint   = local.cluster_internal_endpoint
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  docs               = false
  examples           = false
  config_patches = [yamlencode({
    machine = merge(local.machine_config, {
      nodeLabels = each.value.labels
      nodeTaints = each.value.taints
    })
    cluster = local.config_patches["cluster_${each.value.machine_type}_config"]
  })]
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints = [
    var.cluster_domain,
  ]
}

resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.first_control_plane.public_ipv4
  endpoint             = local.first_control_plane.public_ipv4
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.first_control_plane.public_ipv4
  depends_on = [
    talos_machine_bootstrap.this
  ]
}
