# ==============================================================================
# COMPUTE MODULE VARIABLES
# ==============================================================================

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "instance_name" {
  description = "Name for the VPN server instance"
  type        = string
}

variable "machine_type" {
  description = "Machine type for the VPN instance"
  type        = string
}

variable "zone" {
  description = "GCP zone for the instance"
  type        = string
}

variable "instance_image" {
  description = "VM image for the VPN server"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be deployed"
  type        = string
}

variable "network_tag" {
  description = "Network tag for firewall rules"
  type        = string
}

variable "service_account_name" {
  description = "Name of the service account for the instance"
  type        = string
}

variable "common_labels" {
  description = "Common labels for resources"
  type        = map(string)
  default     = {}
}

variable "preemptible_instance" {
  description = "Use preemptible instance"
  type        = bool
  default     = false
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-standard"
}

variable "enable_ip_forwarding" {
  description = "Enable IP forwarding for VPN functionality"
  type        = bool
  default     = true
}

variable "enable_oslogin" {
  description = "Enable OS Login for SSH access"
  type        = bool
  default     = true
}

variable "enable_shielded_vm" {
  description = "Enable Shielded VM features (secure boot, vTPM, integrity monitoring)"
  type        = bool
  default     = true
}

variable "block_project_ssh_keys" {
  description = "Block project-wide SSH keys to enforce OS Login or per-instance keys"
  type        = bool
  default     = true
}

variable "kms_key_self_link" {
  description = "Customer-managed encryption key self link for boot disk (optional)"
  type        = string
  default     = ""
}

# ==============================================================================
# FIREZONE VARIABLES
# ==============================================================================

variable "firezone_domain" {
  description = "Domain name for Firezone (e.g., vpn.example.com)"
  type        = string
  default     = ""
}

variable "google_workspace_domain" {
  description = "Google Workspace domain for OIDC integration"
  type        = string
  default     = ""
}

variable "firezone_admin_email" {
  description = "Email address for the Firezone administrator account"
  type        = string
}

variable "wireguard_port" {
  description = "UDP port for WireGuard protocol"
  type        = number
  default     = 51820
}