# ==============================================================================
# SECURITY MODULE VARIABLES
# ==============================================================================

variable "resource_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "vpc_name" {
  description = "VPC network name"
  type        = string
}

variable "network_tag" {
  description = "Network tag for firewall targeting"
  type        = string
}

variable "tcp_ports" {
  description = "TCP ports to allow for VPN access"
  type        = list(string)
  default     = ["443", "943"]
}

variable "udp_ports" {
  description = "UDP ports to allow for VPN access"
  type        = list(string)
  default     = ["1194"]
}

variable "allowed_vpn_sources" {
  description = "CIDR blocks allowed for VPN connections"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_ssh_sources" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["35.235.240.0/20"] # Google Identity-Aware Proxy
}