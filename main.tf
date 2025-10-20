# ==============================================================================
# VPN REMOTE ACCESS INFRASTRUCTURE - MAIN CONFIGURATION
#
# This Terraform configuration deploys Firezone Community Edition in GCP
# with Google Workspace SSO integration and WireGuard protocol.
#
# The modular design ensures clean separation of concerns and easier maintenance.
# ==============================================================================

# ==============================================================================
# PROVIDER CONFIGURATION
# ==============================================================================

provider "google" {
  project = var.project_id
  region  = var.region
}

# ==============================================================================
# LOCAL VALUES FOR COMPUTED CONFIGURATIONS
# ==============================================================================

locals {
  # Resource naming with consistent prefix and environment
  resource_prefix = "${var.resource_prefix}-${var.environment}"

  # Network tag for firewall rules
  network_tag = "${var.resource_prefix}-server"

  # Merged labels for consistent resource tagging
  common_labels = merge(var.common_labels, var.project_labels, {
    environment = var.environment
    region      = var.region
  })

  # Firezone port configurations
  firezone_tcp_ports = ["80", "443", "943"]           # HTTP, HTTPS y admin actual
  firezone_udp_ports = [tostring(var.wireguard_port)] # WireGuard protocol
}

# ==============================================================================
# NETWORK MODULE
# 
# Creates VPC, subnet, static IPs, and NAT gateway.
# ==============================================================================

module "network" {
  source = "./modules/network"

  vpc_name                 = var.vpc_name
  region                   = var.region
  resource_prefix          = local.resource_prefix
  enable_flow_logs         = var.enable_flow_logs
  flow_logs_sampling       = var.flow_logs_sampling
  enable_nat_logging       = var.enable_nat_logging
  site_to_site_subnet_cidr = var.site_to_site_subnet_cidr
}

# ==============================================================================
# COMPUTE MODULE - FIREZONE INSTANCE
#
# Firezone Community Edition with Google Workspace SSO integration.
# ==============================================================================

module "compute" {
  source = "./modules/compute"

  project_id     = var.project_id
  instance_name  = var.firezone_instance_name
  machine_type   = var.firezone_machine_type
  zone           = var.zone
  instance_image = var.instance_image
  # Use site-to-site subnet so Firezone can reach partner networks when enabled
  subnet_id            = module.network.site_to_site_subnet_id
  network_tag          = local.network_tag
  service_account_name = var.service_account_name
  common_labels        = local.common_labels
  preemptible_instance = var.preemptible_instance
  disk_size_gb         = var.disk_size_gb
  disk_type            = var.disk_type
  enable_ip_forwarding = var.enable_ip_forwarding
  enable_oslogin       = var.enable_oslogin

  # Firezone specific variables
  firezone_domain         = var.firezone_domain
  google_workspace_domain = var.google_workspace_domain
  firezone_admin_email    = var.firezone_admin_email
  wireguard_port          = var.wireguard_port
}

# ==============================================================================
# LOAD BALANCER MODULE
#
# Creates regional Network Load Balancer with backend services for Firezone.
# ==============================================================================

module "load_balancer" {
  source = "./modules/load-balancer"

  resource_prefix       = local.resource_prefix
  region                = var.region
  zone                  = var.zone
  instance_self_link    = module.compute.instance_self_link
  ingress_ip            = module.network.ingress_ip
  tcp_ports             = local.firezone_tcp_ports
  udp_ports             = local.firezone_udp_ports
  health_check_port     = var.health_check_port
  health_check_interval = var.health_check_interval
  health_check_timeout  = var.health_check_timeout
}

# ==============================================================================
# SECURITY MODULE
#
# Creates firewall rules with defense-in-depth approach for Firezone.
# ==============================================================================

module "security" {
  source = "./modules/security"

  resource_prefix     = local.resource_prefix
  vpc_name            = module.network.vpc_name
  network_tag         = local.network_tag
  tcp_ports           = local.firezone_tcp_ports # CHANGED: Use Firezone ports
  udp_ports           = local.firezone_udp_ports # CHANGED: Use Firezone ports
  allowed_vpn_sources = var.allowed_vpn_sources
  allowed_ssh_sources = var.allowed_ssh_sources
}

# ==============================================================================
# VPN GATEWAY MODULE (OPTIONAL)
#
# Creates IPsec site-to-site VPN tunnels to connect with external organizations.
# Supports IKEv2 with customizable encryption parameters and BGP routing.
# ==============================================================================

module "vpn_gateway" {
  count  = var.enable_site_to_site_vpn ? 1 : 0
  source = "./modules/vpn-gateway"

  resource_prefix = var.resource_prefix
  environment     = var.environment
  region          = var.region
  network_id      = module.network.vpc_id

  # VPN tunnels (Classic VPN with static traffic selectors)
  vpn_tunnels = var.vpn_tunnels

  # VPN secrets from GCP Secret Manager (dynamically built for each tunnel)
  vpn_secrets = {
    for key, tunnel in var.vpn_tunnels :
    key => data.google_secret_manager_secret_version.vpn_psk[key].secret_data
  }
}

# ==============================================================================
# SCHEDULER MODULE (OPTIONAL)
#
# Automates instance start/stop based on business hours to optimize costs.
# When enabled, reduces VM costs by ~70% through automated shutdown.
# ==============================================================================

module "scheduler" {
  source = "./modules/scheduler"

  project_id        = var.project_id
  region            = var.region
  zone              = var.zone
  resource_prefix   = local.resource_prefix
  instance_name     = module.compute.instance_name
  enable_scheduling = var.enable_scheduling
  start_schedule    = var.scheduler_start_schedule
  stop_schedule     = var.scheduler_stop_schedule
  schedule_timezone = var.scheduler_timezone
  scheduler_region  = var.scheduler_region
  common_labels     = local.common_labels
}