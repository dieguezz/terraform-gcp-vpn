# ==============================================================================
# OUTPUT CONFIGURATION FOR VPN REMOTE ACCESS PROJECT
#
# Firezone Community Edition connection information and management commands.
# ==============================================================================

# ==============================================================================
# 🔐 VPN CONNECTION INFORMATION
# ==============================================================================

output "vpn_connection_info" {
  description = "VPN connection information for Firezone"
  value = {
    "🌐 Admin Portal"  = "https://${var.firezone_domain}/admin"
    "👥 Client Portal" = "https://${var.firezone_domain}"
    "📍 Public IP"     = module.network.ingress_ip
  }
  sensitive = false
}

# ==============================================================================
# 🛠️ MANAGEMENT COMMANDS
# ==============================================================================

output "management_commands" {
  description = "Essential management commands"
  value = {
    "🔌 SSH"         = "make ssh"
    "🔑 Credentials" = "make credentials"
    "📝 Logs"        = "make logs"
  }
  sensitive = false
}

# ==============================================================================
# ⏰ SCHEDULER STATUS (if enabled)
# ==============================================================================

output "scheduler_info" {
  description = "Instance scheduling configuration"
  value = var.enable_scheduling ? {
    "✅ Status"   = "Enabled"
    "🌅 Start"    = var.scheduler_start_schedule
    "🌙 Stop"     = var.scheduler_stop_schedule
    "🌍 Timezone" = var.scheduler_timezone
    } : {
    "⏸️  Status" = "Disabled (24/7)"
  }
  sensitive = false
}

# ==============================================================================
# 🔗 SITE-TO-SITE VPN GATEWAY (if enabled)
# ==============================================================================

output "vpn_gateway_info" {
  description = "Site-to-site VPN Gateway status"
  value = var.enable_site_to_site_vpn ? {
    "✅ Status"      = "Enabled"
    "📍 External IP" = module.vpn_gateway[0].vpn_gateway_ip
    "🔗 Tunnels"     = join(", ", [for k, v in module.vpn_gateway[0].tunnel_details : "${k} (${v.detailed_status})"])
    } : {
    "⏸️  Status"     = "Disabled"
    "📍 External IP" = "N/A"
    "🔗 Tunnels"     = "None"
  }
  sensitive = false
}

output "vpn_peer_configuration" {
  description = "Configuration to share with remote VPN administrators"
  value = var.enable_site_to_site_vpn ? {
    "🌐 Our VPN IP"     = module.vpn_gateway[0].configuration_summary.our_vpn_ip
    "🔑 Authentication" = module.vpn_gateway[0].configuration_summary.phase1_auth
    "🔐 IKE Version"    = module.vpn_gateway[0].configuration_summary.ike_version
    "📦 Encapsulation"  = module.vpn_gateway[0].configuration_summary.encapsulation
    "📝 Phase 1"        = "${module.vpn_gateway[0].configuration_summary.phase1_encryption} / ${module.vpn_gateway[0].configuration_summary.phase1_integrity} / ${module.vpn_gateway[0].configuration_summary.phase1_dh_group}"
    "📝 Phase 2"        = "${module.vpn_gateway[0].configuration_summary.phase2_encryption} / ${module.vpn_gateway[0].configuration_summary.phase2_integrity} / PFS ${module.vpn_gateway[0].configuration_summary.phase2_pfs}"
    "📡 Routing"        = module.vpn_gateway[0].configuration_summary.routing_type
  } : {
    "⏸️  Status" = "VPN Gateway disabled"
  }
  sensitive = false
}

# ==============================================================================
# 🖥️ INSTANCE INFORMATION (for Makefile automation - internal use)
# ==============================================================================

output "instance_name" {
  description = "Firezone instance name (internal - used by Makefile)"
  value       = module.compute.instance_name
}

output "instance_zone" {
  description = "Firezone instance zone (internal - used by Makefile)"
  value       = module.compute.instance_zone
}
