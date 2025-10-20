# Minimal example: basic remote access VPN

provider "google" {
  project = var.project_id
  region  = var.region
}

module "vpn" {
  source = "../.."  # Root module

  project_id              = var.project_id
  region                  = var.region
  zone                    = var.zone
  firezone_domain         = var.firezone_domain
  firezone_admin_email    = var.firezone_admin_email
  google_workspace_domain = var.google_workspace_domain

  enable_site_to_site_vpn = false
  enable_scheduling       = false
}

output "admin_portal" {
  value       = "https://${var.firezone_domain}/admin"
  description = "Firezone admin portal URL"
}
