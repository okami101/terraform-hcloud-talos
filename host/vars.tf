variable "location" {
  description = "The location to use for the servers"
  type        = string
}

variable "type" {
  description = "The server type to use for the servers"
  type        = string
}

variable "name" {
  description = "The name to use for the servers"
  type        = string
}

variable "hcloud_firewall_ids" {
  description = "List of firewall IDs to attach to the server"
  type        = list(number)
  default     = []
}

variable "private_ipv4" {
  description = "The private IPv4 address to use for the server"
  type        = string
}

variable "hcloud_network_id" {
  description = "The network ID to use for the server"
  type        = number
}

variable "hcloud_volumes" {
  description = "List of volumes to attach to the server"
  type = list(object({
    name = string
    size = number
  }))
  default = []
}
