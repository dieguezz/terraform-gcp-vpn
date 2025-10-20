# ==============================================================================
# NETWORK MODULE - VPC, SUBNET, NAT AND STATIC IPS
#
# This module creates the core network infrastructure for Firezone deployment.
# ==============================================================================

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ==============================================================================
# VPC AND SUBNET
# ==============================================================================

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

# Site-to-Site VPN subnet (partner encryption domain)
# Always created - required for Firezone instance deployment
resource "google_compute_subnetwork" "site_to_site_subnet" {
  name          = "${var.resource_prefix}-site-to-site-subnet"
  ip_cidr_range = var.site_to_site_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id

  # Enable VPC Flow Logs for security monitoring
  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = var.flow_logs_sampling
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}

# ==============================================================================
# STATIC IP ADDRESSES
# ==============================================================================

resource "google_compute_address" "ingress_ip" {
  name   = "${var.resource_prefix}-ingress-ip"
  region = var.region
}

resource "google_compute_address" "egress_ip" {
  name   = "${var.resource_prefix}-egress-ip"
  region = var.region
}

# ==============================================================================
# CLOUD NAT FOR EGRESS TRAFFIC
# ==============================================================================

resource "google_compute_router" "router" {
  name    = "${var.resource_prefix}-router"
  network = google_compute_network.vpc.id
  region  = var.region
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.resource_prefix}-nat-gateway"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  # Site-to-site subnet NAT configuration
  subnetwork {
    name                    = google_compute_subnetwork.site_to_site_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.egress_ip.self_link]

  # Enable NAT logging for egress traffic monitoring
  dynamic "log_config" {
    for_each = var.enable_nat_logging ? [1] : []
    content {
      enable = true
      filter = "TRANSLATIONS_ONLY"
    }
  }
}