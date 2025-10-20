# ==============================================================================
# LOAD BALANCER MODULE - REGIONAL NETWORK LOAD BALANCER
#
# This module creates a regional Network Load Balancer for Firezone.
# ==============================================================================

# ==============================================================================
# INSTANCE GROUP
# ==============================================================================

resource "google_compute_instance_group" "vpn_ig" {
  name        = "${var.resource_prefix}-ig"
  zone        = var.zone
  instances   = [var.instance_self_link]

  named_port {
    name = "http"
    port = 80
  }

  named_port {
    name = "https"
    port = 443
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ==============================================================================
# HEALTH CHECK
# ==============================================================================

resource "google_compute_region_health_check" "vpn_hc_tcp" {
  name   = "${var.resource_prefix}-health-check-tcp"
  region = var.region

  check_interval_sec  = var.health_check_interval
  timeout_sec         = var.health_check_timeout
  healthy_threshold   = 2
  unhealthy_threshold = 3

  tcp_health_check {
    port = var.health_check_port
  }

  log_config {
    enable = true
  }
}

# ==============================================================================
# BACKEND SERVICES
# ==============================================================================

resource "google_compute_region_backend_service" "vpn_backend_tcp" {
  name                  = "${var.resource_prefix}-backend-tcp"
  region                = var.region
  protocol              = "TCP"
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_region_health_check.vpn_hc_tcp.id]
  session_affinity      = "NONE"

  backend {
    group          = google_compute_instance_group.vpn_ig.self_link
    balancing_mode = "CONNECTION"
  }
}

resource "google_compute_region_backend_service" "vpn_backend_udp" {
  name                  = "${var.resource_prefix}-backend-udp"
  region                = var.region
  protocol              = "UDP"
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_region_health_check.vpn_hc_tcp.id]
  session_affinity      = "NONE"

  backend {
    group          = google_compute_instance_group.vpn_ig.self_link
    balancing_mode = "CONNECTION"
  }
}

# ==============================================================================
# FORWARDING RULES
# ==============================================================================

resource "google_compute_forwarding_rule" "vpn_fr_tcp" {
  name                  = "${var.resource_prefix}-forwarding-rule-tcp"
  region                = var.region
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
  ip_address            = var.ingress_ip
  backend_service       = google_compute_region_backend_service.vpn_backend_tcp.id

  # Firezone TCP ports
  ports = var.tcp_ports
}

resource "google_compute_forwarding_rule" "vpn_fr_udp" {
  name                  = "${var.resource_prefix}-forwarding-rule-udp"
  region                = var.region
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "UDP"
  ip_address            = var.ingress_ip
  backend_service       = google_compute_region_backend_service.vpn_backend_udp.id

  # Firezone WireGuard port
  ports = var.udp_ports
}