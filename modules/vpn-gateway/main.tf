# ==============================================================================
# GCP CLASSIC VPN GATEWAY MODULE - IPSEC SITE-TO-SITE
#
# Creates a Classic VPN Gateway for IPsec site-to-site connectivity with
# external organizations. Uses policy-based routing with static traffic selectors.
# Supports IKEv2 with customizable encryption parameters.
#
# Architecture: Classic VPN (policy-based) without BGP
# ==============================================================================

terraform {
  required_version = ">= 1.6.0, < 2.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.4.0, < 8.0.0"
    }
  }
}

# Static IP address for VPN Gateway
resource "google_compute_address" "vpn_static_ip" {
  name   = "${var.resource_prefix}-vpn-gateway-ip-${var.environment}"
  region = var.region
}

# Forwarding rules for ESP, UDP 500, UDP 4500
resource "google_compute_forwarding_rule" "vpn_esp" {
  name        = "${var.resource_prefix}-vpn-esp-${var.environment}"
  region      = var.region
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.id
}

resource "google_compute_forwarding_rule" "vpn_udp500" {
  name        = "${var.resource_prefix}-vpn-udp500-${var.environment}"
  region      = var.region
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.id
}

resource "google_compute_forwarding_rule" "vpn_udp4500" {
  name        = "${var.resource_prefix}-vpn-udp4500-${var.environment}"
  region      = var.region
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.id
}

# Classic VPN Gateway
resource "google_compute_vpn_gateway" "vpn_gateway" {
  name    = "${var.resource_prefix}-vpn-gateway-${var.environment}"
  network = var.network_id
  region  = var.region
}

# VPN Tunnel configuration with static traffic selectors
resource "google_compute_vpn_tunnel" "tunnels" {
  for_each = var.vpn_tunnels

  name          = "${var.resource_prefix}-tunnel-${each.key}"
  region        = var.region
  peer_ip       = each.value.peer_ip
  shared_secret = var.vpn_secrets[each.key]

  target_vpn_gateway = google_compute_vpn_gateway.vpn_gateway.id

  # Traffic selectors (policy-based routing)
  local_traffic_selector  = each.value.local_traffic_selector
  remote_traffic_selector = each.value.remote_traffic_selector

  # IKE version
  ike_version = 2

  # Depends on forwarding rules
  depends_on = [
    google_compute_forwarding_rule.vpn_esp,
    google_compute_forwarding_rule.vpn_udp500,
    google_compute_forwarding_rule.vpn_udp4500,
  ]
}

# Static routes for each remote network
resource "google_compute_route" "vpn_routes" {
  for_each = {
    for item in flatten([
      for tunnel_key, tunnel in var.vpn_tunnels : [
        for idx, dest in tunnel.remote_traffic_selector : {
          key         = "${tunnel_key}-${idx}"
          tunnel_key  = tunnel_key
          dest_range  = dest
          tunnel_name = google_compute_vpn_tunnel.tunnels[tunnel_key].name
          peer_name   = tunnel.peer_name
        }
      ]
    ]) : item.key => item
  }

  name                = "${var.resource_prefix}-route-${each.value.tunnel_key}-${each.key}"
  network             = var.network_id
  dest_range          = each.value.dest_range
  next_hop_vpn_tunnel = each.value.tunnel_name
  priority            = 1000

  # No tags - route applies to ALL instances in the VPC
  # tags = ["vpn-route"]  # Removed: This would restrict route to tagged instances only
}

# Firewall rules to allow traffic from VPN tunnels (INGRESS)
resource "google_compute_firewall" "allow_vpn_inbound" {
  for_each = var.vpn_tunnels

  name      = "${var.resource_prefix}-allow-vpn-inbound-${each.key}"
  network   = var.network_id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  # Allow traffic FROM remote networks
  source_ranges = each.value.remote_traffic_selector

  description = "Allow inbound traffic from ${each.value.peer_name} VPN tunnel"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Firewall rules to allow traffic TO VPN tunnels (EGRESS)
resource "google_compute_firewall" "allow_vpn_outbound" {
  for_each = var.vpn_tunnels

  name      = "${var.resource_prefix}-allow-vpn-outbound-${each.key}"
  network   = var.network_id
  direction = "EGRESS"

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  # Allow traffic TO remote networks
  destination_ranges = each.value.remote_traffic_selector

  description = "Allow outbound traffic to ${each.value.peer_name} VPN tunnel"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}
