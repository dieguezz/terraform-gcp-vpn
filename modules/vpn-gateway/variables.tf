# ==============================================================================
# VPN GATEWAY MODULE VARIABLES - CLASSIC VPN
# ==============================================================================

variable "resource_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "GCP region for VPN Gateway"
  type        = string
}

variable "network_id" {
  description = "Self-link of the VPC network"
  type        = string
}

variable "vpn_tunnels" {
  description = <<-EOT
    Map of VPN tunnel configurations for Classic VPN with policy-based routing.
    Each tunnel uses static traffic selectors (no BGP).
    
    Example for a partner connection:
    {
      "partner_a" = {
        peer_name                = "Partner A"
        peer_ip                  = "203.0.113.10"
        local_traffic_selector   = ["10.200.0.0/24"]
        remote_traffic_selector  = ["198.51.100.0/24"]
      }
    }
    
    IPsec parameters (GCP Classic VPN defaults):
    - IKEv2 with preshared key authentication
    - Phase 1: AES-256-CBC, SHA2-256, DH Group 14
    - Phase 2: AES-256-CBC, SHA2-256, PFS Group 14
    - ESP encapsulation
    
    Note: Preshared keys are stored in GCP Secret Manager and passed via vpn_secrets variable.
  EOT
  type = map(object({
    peer_name               = string
    peer_ip                 = string
    local_traffic_selector  = list(string)
    remote_traffic_selector = list(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.vpn_tunnels :
      can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$", v.peer_ip))
    ])
    error_message = "All peer_ip values must be valid IPv4 addresses."
  }

  validation {
    condition = alltrue([
      for k, v in var.vpn_tunnels :
      length(v.local_traffic_selector) > 0 && length(v.remote_traffic_selector) > 0
    ])
    error_message = "Both local_traffic_selector and remote_traffic_selector must have at least one CIDR."
  }
}

variable "vpn_secrets" {
  description = <<-EOT
    Map of VPN tunnel preshared keys retrieved from GCP Secret Manager.
    Keys must match tunnel names in vpn_tunnels variable.
    
    Example:
    {
      "partner_a" = "<secret-value-from-secret-manager>"
    }
    
    This variable is typically populated from Secret Manager data sources in the root module.
  EOT
  type      = map(string)
  sensitive = true
  default   = {}

  validation {
    condition = alltrue([
      for k, v in var.vpn_secrets :
      length(v) >= 8
    ])
    error_message = "All preshared keys must be at least 8 characters long."
  }
}
