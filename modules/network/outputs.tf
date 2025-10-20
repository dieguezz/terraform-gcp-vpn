# ==============================================================================
# NETWORK MODULE OUTPUTS
# ==============================================================================

output "vpc_id" {
  description = "VPC network ID"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "ingress_ip" {
  description = "Static public IP for ingress traffic"
  value       = google_compute_address.ingress_ip.address
}

output "site_to_site_subnet_id" {
  description = "Site-to-site VPN subnet ID"
  value       = google_compute_subnetwork.site_to_site_subnet.id
}