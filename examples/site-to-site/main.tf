# Example: VPN with a site-to-site partner tunnel

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

  enable_site_to_site_vpn = true
  enable_scheduling       = false

  vpn_tunnels = {
    partner_a = {
      peer_name               = var.partner_peer_name
      peer_ip                 = var.partner_peer_ip
      local_traffic_selector  = var.partner_local_selectors
      remote_traffic_selector = var.partner_remote_selectors
    }
  }
}

output "tunnel_configuration_summary" {
  value       = module.vpn.vpn_connection_info
  description = "Connection info plus partner tunnel setup"
}
