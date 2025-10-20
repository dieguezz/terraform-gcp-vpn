# ==============================================================================
# SECRET MANAGER INTEGRATION
#
# Dynamically retrieves VPN preshared keys from GCP Secret Manager.
# Secret naming convention: vpn-psk-{tunnel_key}
# Example: vpn-psk-partner-a, vpn-psk-partner-b, etc.
#
# Secrets are managed centrally and accessible by authorized groups/users.
# ==============================================================================

data "google_secret_manager_secret_version" "vpn_psk" {
  for_each = var.vpn_tunnels

  secret  = "vpn-psk-${each.key}"
  project = var.project_id
}
