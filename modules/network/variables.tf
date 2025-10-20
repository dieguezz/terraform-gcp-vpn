# ==============================================================================
# NETWORK MODULE VARIABLES
# ==============================================================================

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "region" {
  description = "GCP region for regional resources"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs for network monitoring"
  type        = bool
  default     = true
}

variable "flow_logs_sampling" {
  description = "VPC Flow Logs sampling rate"
  type        = number
  default     = 1.0
}

variable "enable_nat_logging" {
  description = "Enable Cloud NAT logging for egress monitoring"
  type        = bool
  default     = true
}

variable "site_to_site_subnet_cidr" {
  description = "CIDR block for the site-to-site VPN subnet (partner encryption domain)"
  type        = string
  default     = ""
}