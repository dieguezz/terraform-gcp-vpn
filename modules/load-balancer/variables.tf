# ==============================================================================
# LOAD BALANCER MODULE VARIABLES
# ==============================================================================

variable "resource_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "region" {
  description = "GCP region for the load balancer"
  type        = string
}

variable "zone" {
  description = "GCP zone for the instance group"
  type        = string
}

variable "instance_self_link" {
  description = "Self link of the VPN server instance"
  type        = string
}

variable "ingress_ip" {
  description = "Static IP address for the load balancer"
  type        = string
}

variable "tcp_ports" {
  description = "TCP ports for the load balancer"
  type        = list(string)
  default     = ["443", "943"]
}

variable "udp_ports" {
  description = "UDP ports for the load balancer"
  type        = list(string)
  default     = ["1194"]
}

variable "health_check_port" {
  description = "Port for health checks"
  type        = number
  default     = 943
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 10
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}