# ==============================================================================
# COMPUTE MODULE - FIREZONE VPN SERVER INSTANCE
#
# Firezone Community Edition with Google Workspace SSO integration.
# ==============================================================================

# ==============================================================================
# SERVICE ACCOUNT CONFIGURATION
# ==============================================================================

data "google_service_account" "vpn_sa" {
  account_id = var.service_account_name
  project    = var.project_id
}

resource "google_project_iam_member" "vpn_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${data.google_service_account.vpn_sa.email}"
}

resource "google_project_iam_member" "vpn_sa_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${data.google_service_account.vpn_sa.email}"
}

# ==============================================================================
# FIREZONE VPN SERVER INSTANCE
# ==============================================================================

resource "google_compute_instance" "vpn_server" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  # Allow stopping the instance to update configuration
  allow_stopping_for_update = true

  tags = [var.network_tag, "firezone-server"]
  labels = merge(var.common_labels, {
    software = "firezone-community"
    role     = "vpn-server"
    protocol = "wireguard"
  })

  scheduling {
    preemptible         = var.preemptible_instance
    automatic_restart   = !var.preemptible_instance
    on_host_maintenance = var.preemptible_instance ? "TERMINATE" : "MIGRATE"
  }

  boot_disk {
    initialize_params {
      image = var.instance_image
      size  = var.disk_size_gb
      type  = var.disk_type
    }
  }

  network_interface {
    subnetwork = var.subnet_id
    # No external IP - traffic flows through Load Balancer and NAT
  }

  can_ip_forward = var.enable_ip_forwarding

  service_account {
    email = data.google_service_account.vpn_sa.email
    scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write"
    ]
  }

  metadata = {
    enable-oslogin = var.enable_oslogin ? "TRUE" : "FALSE"
  }

  # Firezone installation and configuration script
  metadata_startup_script = templatefile("${path.module}/../../scripts/firezone-install.sh", {
    firezone_domain         = var.firezone_domain
    google_workspace_domain = var.google_workspace_domain
    firezone_admin_email    = var.firezone_admin_email
    wireguard_port          = var.wireguard_port
  })
}