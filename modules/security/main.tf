# ==============================================================================
# SECURITY MODULE - FIREWALL RULES
#
# Defense-in-depth security configuration with explicit allow/deny rules.
# These rules work for Firezone deployment.
# ==============================================================================

# ==============================================================================
# VPN CLIENT ACCESS RULES
# ==============================================================================

resource "google_compute_firewall" "allow_vpn_access" {
  name      = "${var.resource_prefix}-allow-vpn-access"
  network   = var.vpc_name
  direction = "INGRESS"
  priority  = 1000

  source_ranges = var.allowed_vpn_sources
  target_tags   = [var.network_tag]

  # Firezone TCP ports
  dynamic "allow" {
    for_each = var.tcp_ports
    content {
      protocol = "tcp"
      ports    = [allow.value]
    }
  }

  dynamic "allow" {
    for_each = var.udp_ports
    content {
      protocol = "udp"
      ports    = [allow.value]
    }
  }
}

# ==============================================================================
# SSH ACCESS RULES
# ==============================================================================

resource "google_compute_firewall" "allow_ssh_via_iap" {
  name      = "${var.resource_prefix}-allow-ssh-iap"
  network   = var.vpc_name
  direction = "INGRESS"
  priority  = 1000

  source_ranges = var.allowed_ssh_sources
  target_tags   = [var.network_tag]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# ==============================================================================
# EGRESS RULES
# ==============================================================================

resource "google_compute_firewall" "allow_egress" {
  name      = "${var.resource_prefix}-allow-egress"
  network   = var.vpc_name
  direction = "EGRESS"
  priority  = 1000

  destination_ranges = ["0.0.0.0/0"]
  target_tags        = [var.network_tag]

  allow {
    protocol = "all"
  }
}