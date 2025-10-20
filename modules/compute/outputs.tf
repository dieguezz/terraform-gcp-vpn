# ==============================================================================
# COMPUTE MODULE OUTPUTS
# ==============================================================================

output "instance_name" {
  description = "VPN server instance name"
  value       = google_compute_instance.vpn_server.name
}

output "instance_zone" {
  description = "VPN server instance zone"
  value       = google_compute_instance.vpn_server.zone
}

output "instance_self_link" {
  description = "VPN server instance self link"
  value       = google_compute_instance.vpn_server.self_link
}