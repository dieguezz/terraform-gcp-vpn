# Example: VPN with business-hours scheduling enabled

provider "google" {
  project = var.project_id
  region  = var.region
}

module "vpn" {
  source = "../.."

  project_id              = var.project_id
  region                  = var.region
  zone                    = var.zone
  firezone_domain         = var.firezone_domain
  firezone_admin_email    = var.firezone_admin_email
  google_workspace_domain = var.google_workspace_domain

  enable_scheduling       = true
  enable_site_to_site_vpn = false

  scheduler_start_schedule = var.scheduler_start_schedule
  scheduler_stop_schedule  = var.scheduler_stop_schedule
  scheduler_timezone       = var.scheduler_timezone
}

output "scheduler_status" {
  value       = module.vpn.scheduler_info
  description = "Details of scheduling configuration"
}
