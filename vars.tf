variable "talos_version" {
  description = "The version of talos to use"
  type        = string
}

variable "kubernetes_version" {
  description = "The version of kubernetes to use"
  type        = string
}

variable "cluster_name" {
  description = "The cluster name, will be used in the node name, in the form of {cluster_name}-{nodepool_name}"
  type        = string
  default     = "talos"
}

variable "cluster_domain" {
  description = "The domain name of the cluster"
  type        = string
  default     = "cluster.local"
}

variable "network_zone" {
  description = "The network zone where to attach hcloud resources"
  type        = string
  default     = "eu-central"
}

variable "network_ipv4_cidr" {
  description = "The main network cidr that all subnets will be created upon."
  type        = string
  default     = "10.0.0.0/8"
}

variable "firewall_kube_api_source" {
  description = "IP sources that are allowed to access the kube API"
  type        = list(string)
  default = [
    "0.0.0.0/0",
    "::/0"
  ]
}

variable "firewall_talos_api_source" {
  description = "IP sources that are allowed to access the servers via SSH"
  type        = list(string)
  default = [
    "0.0.0.0/0",
    "::/0"
  ]
}

variable "control_planes" {
  description = "List of control planes"
  type = list(object({
    name        = string
    server_type = string
    location    = string
    labels      = optional(map(string))
    taints      = optional(map(string))
  }))
}

variable "agent_nodepools" {
  description = "List of all additional worker types to create for cluster. Each type is identified by specific role and can have a different number of instances."
  type = list(object({
    name        = string
    server_type = string
    location    = string
    count       = number
    labels      = optional(map(string))
    taints      = optional(map(string))
    volume_size = optional(number)
  }))
}
