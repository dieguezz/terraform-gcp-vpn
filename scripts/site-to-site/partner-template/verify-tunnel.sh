#!/usr/bin/env bash
set -euo pipefail

# Partner template configuration. Copy this folder, rename it, and adjust the
# defaults below so they match the resources created for the new tunnel.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
COMMON_DIR=$(cd "${SCRIPT_DIR}/../common" && pwd)

export PARTNER_NAME="${PARTNER_NAME:-partner-template}"
export VPN_TUNNEL_NAME="${VPN_TUNNEL_NAME:-vpn-tunnel-partner}"
export VPN_REGION="${VPN_REGION:-europe-southwest1}"
export VPN_GATEWAY_ADDRESS_NAME="${VPN_GATEWAY_ADDRESS_NAME:-vpn-gateway-ip}"
export VPN_ROUTE_FILTER="${VPN_ROUTE_FILTER:-vpn-route-partner}"
export VPN_FIREWALL_FILTER="${VPN_FIREWALL_FILTER:-vpn-allow-partner}"

bash "${COMMON_DIR}/verify-tunnel.sh"
