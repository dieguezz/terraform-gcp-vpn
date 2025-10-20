# ==============================================================================
# VARIABLES FOR VPN REMOTE ACCESS PROJECT
#
# Firezone Community Edition deployment with Google Workspace SSO integration
# and WireGuard protocol for modern, secure VPN access.
#
# See README.md for complete deployment and configuration details.
# ==============================================================================

# ==============================================================================
# CORE PROJECT CONFIGURATION
# ==============================================================================

variable "project_id" {
  description = "GCP project ID where the VPN infrastructure will be deployed"
  type        = string
  default     = "demo-gcp-project"
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID cannot be empty."
  }
}

variable "region" {
  description = "GCP region for regional resources (Load Balancer, NAT, Static IPs, Cloud Functions). Must contain the zone specified in 'var.zone'."
  type        = string
  default     = "europe-southwest1"
  # Note: This region contains resources like Load Balancer, NAT gateway, and Firewall.
  # The zone (e.g., europe-southwest1-a) must be within this region.
  # Cloud Scheduler region (scheduler_region) can differ - see modules/scheduler for details.
}

variable "zone" {
  description = "GCP zone for VM instance. MUST be within the region specified in 'var.region' (e.g., 'europe-southwest1-a' is in 'europe-southwest1')."
  type        = string
  default     = "europe-southwest1-a"
  # Validation: This zone must be within the specified region.
  # Example: If region=europe-southwest1, zone must be europe-southwest1-a, -b, or -c
}

variable "instance_image" {
  description = "GCP image family or image name for the VPN server instance (e.g., 'ubuntu-os-cloud/ubuntu-2204-lts')"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
  # Use 'gcloud compute images list --project=ubuntu-os-cloud' to find available images
}

# ==============================================================================
# NETWORKING CONFIGURATION
# ==============================================================================

variable "vpc_name" {
  description = "Name for the VPC network"
  type        = string
  default     = "vpn-vpc"
}

variable "service_account_name" {
  description = "Name of the existing service account for the VPN server (without @project.iam.gserviceaccount.com)"
  type        = string
  default     = "sa-vpn-server"
}

variable "site_to_site_subnet_cidr" {
  description = "CIDR block for the site-to-site VPN subnet (used for partner connections)"
  type        = string
  default     = "10.200.0.0/24"
  validation {
    condition     = can(cidrhost(var.site_to_site_subnet_cidr, 0))
    error_message = "Site-to-site subnet CIDR must be a valid IPv4 CIDR block."
  }
}

# ==============================================================================
# VPN ROUTING CONFIGURATION
# ==============================================================================


# ==============================================================================
# SITE-TO-SITE VPN GATEWAY CONFIGURATION
# ==============================================================================

variable "enable_site_to_site_vpn" {
  description = <<-EOT
    Enable Classic IPsec site-to-site VPN Gateway for connecting with external organizations.
    Creates a Classic VPN Gateway with IKEv2 and policy-based routing (static traffic selectors).
    Uses static routes instead of BGP for compatibility with traditional VPN implementations.
  EOT
  type        = bool
  default     = false
}

variable "vpn_tunnels" {
  description = <<-EOT
    Map of VPN tunnels to create for site-to-site connections using Classic VPN.
    Uses policy-based routing with static traffic selectors (no BGP).
    
    Example configuration for a partner connection:
    {
      "partner_a" = {
        peer_name                = "Partner A"
        peer_ip                  = "203.0.113.10"
        local_traffic_selector   = ["10.200.0.0/24"]
        remote_traffic_selector  = ["198.51.100.0/24"]
      }
    }
    
    IMPORTANT: 
    - local_traffic_selector: Your local networks that the partner will access
    - remote_traffic_selector: Partner networks that you will access
    - Preshared keys are stored in GCP Secret Manager for security
    
    IPsec Parameters (automatically configured):
    - IKEv2 with preshared key authentication
    - Phase 1: AES-256, SHA-256, DH Group 14, lifetime 86400s
    - Phase 2: AES-256, SHA-256, PFS Group 14, lifetime 3600s
    - DPD: 10 seconds, retry 2
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
}


# ==============================================================================
# LOAD BALANCER AND NETWORKING
# ==============================================================================

variable "health_check_port" {
  description = "Port for health checks (Firezone HTTPS admin interface)"
  type        = number
  default     = 443
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 10
  validation {
    condition     = var.health_check_interval >= 5 && var.health_check_interval <= 60
    error_message = "Health check interval must be between 5 and 60 seconds."
  }
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
  validation {
    condition     = var.health_check_timeout >= 1 && var.health_check_timeout <= 30
    error_message = "Health check timeout must be between 1 and 30 seconds."
  }
}

# ==============================================================================
# FIREZONE CONFIGURATION VARIABLES
# ==============================================================================

variable "firezone_domain" {
  description = <<-EOT
    Domain name for Firezone access (e.g., vpn.company.com).
    This domain should be configured to point to the vpn_ingress_ip.
    Required for SSL certificate generation and proper operation.
  EOT
  type        = string
  default     = ""
}

variable "firezone_instance_name" {
  description = "Name for the Firezone server instance"
  type        = string
  default     = "firezone-server-instance"
}

variable "firezone_machine_type" {
  description = "Machine type for Firezone (e2-medium recommended for Docker + Firezone)"
  type        = string
  default     = "e2-medium"
}

variable "google_workspace_domain" {
  description = <<-EOT
    Google Workspace domain for SSO integration.
    Users from this domain will be able to authenticate via OIDC.
  Example: example.com
  EOT
  type        = string
  default     = ""
}

variable "firezone_admin_email" {
  description = "Email address for the Firezone administrator account. This account will have full administrative privileges"
  type        = string
}

variable "wireguard_port" {
  description = "UDP port for WireGuard protocol in Firezone"
  type        = number
  default     = 51820
}

# ==============================================================================
# SECURITY AND MONITORING
# ==============================================================================

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs for network monitoring"
  type        = bool
  default     = true
}

variable "flow_logs_sampling" {
  description = "VPC Flow Logs sampling rate (1.0 = 100%, 0.5 = 50%)"
  type        = number
  default     = 1.0
  validation {
    condition     = var.flow_logs_sampling >= 0.1 && var.flow_logs_sampling <= 1.0
    error_message = "Flow logs sampling must be between 0.1 and 1.0."
  }
}

variable "enable_nat_logging" {
  description = "Enable Cloud NAT logging for egress monitoring"
  type        = bool
  default     = true
}

variable "enable_oslogin" {
  description = "Enable OS Login for SSH access (recommended for production)"
  type        = bool
  default     = true
}

# ==============================================================================
# FIREWALL CONFIGURATION
# ==============================================================================

variable "allowed_ssh_sources" {
  description = "CIDR blocks allowed for SSH access (default: IAP range only)"
  type        = list(string)
  default     = ["35.235.240.0/20"] # Google Identity-Aware Proxy
  validation {
    condition = alltrue([
      for cidr in var.allowed_ssh_sources : can(cidrhost(cidr, 0))
    ])
    error_message = "All SSH source CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "allowed_vpn_sources" {
  description = "CIDR blocks allowed for VPN connections (default: anywhere)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  validation {
    condition = alltrue([
      for cidr in var.allowed_vpn_sources : can(cidrhost(cidr, 0))
    ])
    error_message = "All VPN source CIDRs must be valid IPv4 CIDR blocks."
  }
}

# ==============================================================================
# RESOURCE NAMING
# ==============================================================================

variable "resource_prefix" {
  description = "Prefix for all resource names (useful for multi-environment deployments)"
  type        = string
  default     = "vpn"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.resource_prefix)) && length(var.resource_prefix) <= 10
    error_message = "Resource prefix must start with a letter, contain only lowercase letters, numbers, and hyphens, and be 10 characters or less."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod) - used in resource naming and tagging"
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# ==============================================================================
# LABELS AND METADATA
# ==============================================================================

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    project    = "vpn-remote-access"
    managed-by = "terraform"
    solution   = "firezone"
    component  = "vpn-infrastructure"
  }
}

variable "project_labels" {
  description = "Additional project-specific labels"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# ADVANCED CONFIGURATION
# ==============================================================================

variable "enable_ip_forwarding" {
  description = "Enable IP forwarding on the VPN instance (required for VPN functionality)"
  type        = bool
  default     = true
}

variable "enable_shielded_vm" {
  description = "Enable Shielded VM features (secure boot, vTPM, integrity monitoring) for the VPN instance"
  type        = bool
  default     = true
}

variable "block_project_ssh_keys" {
  description = "Block project-wide SSH keys on the instance to enforce OS Login or per-instance keys"
  type        = bool
  default     = true
}

variable "kms_key_self_link" {
  description = "Customer-managed encryption key self link for the VPN instance boot disk (optional). Leave empty to use Google-managed encryption."
  type        = string
  default     = ""
}

variable "allowed_egress_destinations" {
  description = "CIDR ranges allowed for egress traffic from the VPN instance (egress firewall). Default is unrestricted."
  type        = list(string)
  default     = ["0.0.0.0/0"]
  validation {
    condition = length(var.allowed_egress_destinations) > 0 && alltrue([
      for cidr in var.allowed_egress_destinations : can(cidrhost(cidr, 0))
    ])
    error_message = "All egress destination CIDRs must be valid IPv4 CIDR blocks and list cannot be empty."
  }
}

variable "scheduler_bucket_kms_key" {
  description = "Customer-managed encryption key self link for the Cloud Functions source bucket (optional). Leave empty for Google-managed encryption."
  type        = string
  default     = ""
}


variable "preemptible_instance" {
  description = "Use preemptible instance for cost savings (not recommended for production)"
  type        = bool
  default     = false
}

variable "disk_size_gb" {
  description = "Boot disk size in GB for the VPN instance"
  type        = number
  default     = 20
  validation {
    condition     = var.disk_size_gb >= 10 && var.disk_size_gb <= 100
    error_message = "Disk size must be between 10 and 100 GB."
  }
}

variable "disk_type" {
  description = "Boot disk type (pd-standard, pd-ssd, pd-balanced)"
  type        = string
  default     = "pd-standard"
  validation {
    condition     = contains(["pd-standard", "pd-ssd", "pd-balanced"], var.disk_type)
    error_message = "Disk type must be one of: pd-standard, pd-ssd, pd-balanced."
  }
}

# ==============================================================================
# SCHEDULER MODULE - COST OPTIMIZATION
# ==============================================================================

variable "enable_scheduling" {
  description = "Enable automated instance start/stop scheduling during business hours. Uses Cloud Scheduler and Cloud Functions to reduce costs"
  type        = bool
  default     = true
}

variable "scheduler_start_schedule" {
  description = "Cloud Scheduler cron expression for starting the instance (default: 7am Mon-Fri). Format: 'minute hour day month weekday'"
  type        = string
  default     = "0 7 * * 1-5"
}

variable "scheduler_stop_schedule" {
  description = "Cloud Scheduler cron expression for stopping the instance (default: 8pm Mon-Fri). Format: 'minute hour day month weekday'"
  type        = string
  default     = "0 20 * * 1-5"
}

variable "scheduler_timezone" {
  description = "Timezone for scheduler jobs (IANA format). Default: Europe/Madrid"
  type        = string
  default     = "Europe/Madrid"
}

variable "scheduler_region" {
  description = "GCP region for Cloud Scheduler jobs. Must be a Cloud Scheduler supported region (e.g., europe-west1, us-central1). Cloud Scheduler is not available in all regions"
  type        = string
  default     = "europe-west1"
}

