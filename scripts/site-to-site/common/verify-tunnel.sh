#!/usr/bin/env bash
set -euo pipefail

readonly PARTNER_LABEL=${PARTNER_NAME:-"unknown"}
readonly TUNNEL_NAME=${VPN_TUNNEL_NAME:-}
readonly REGION=${VPN_REGION:-}
readonly ADDRESS_NAME=${VPN_GATEWAY_ADDRESS_NAME:-vpn-gateway-ip}
readonly ROUTE_FILTER=${VPN_ROUTE_FILTER:-vpn-route}
readonly FIREWALL_FILTER=${VPN_FIREWALL_FILTER:-vpn-allow}
readonly LOG_RESOURCE_FILTER=${VPN_LOG_RESOURCE_FILTER:-resource.type=vpn_gateway}

if [ -z "${TUNNEL_NAME}" ]; then
  echo "VPN_TUNNEL_NAME is not set. Export it before running the shared verifier." >&2
  exit 1
fi

if [ -z "${REGION}" ]; then
  echo "VPN_REGION is not set. Export it before running the shared verifier." >&2
  exit 1
fi

if ! command -v gcloud >/dev/null 2>&1; then
  echo "gcloud CLI is required but not found in PATH." >&2
  exit 1
fi

cat <<EOF
==========================================
🔍 Site-to-Site VPN Verification
==========================================
Partner     : ${PARTNER_LABEL}
Tunnel      : ${TUNNEL_NAME}
Region      : ${REGION}
Timestamp   : $(date -Iseconds)
==========================================
EOF

echo
printf '1️⃣  VPN Gateway IPs\n---\n'
if [ -n "${ADDRESS_NAME}" ]; then
  if ! gcloud compute addresses list \
    --filter="name:${ADDRESS_NAME}" \
    --format="table(address,status,name,region)"; then
    echo "Unable to list addresses matching filter 'name:${ADDRESS_NAME}'."
  fi
else
  echo "(address listing skipped; set VPN_GATEWAY_ADDRESS_NAME to enable)"
fi
printf '\n'

printf '2️⃣  Gateway Status\n---\n'
if ! gcloud compute vpn-gateways list \
  --filter="region:${REGION}" \
  --format="table(name,network,region)"; then
  echo "Unable to list VPN gateways in region ${REGION}."
fi
printf '\n'

printf '3️⃣  Tunnel Status\n---\n'
if ! gcloud compute vpn-tunnels describe "${TUNNEL_NAME}" \
  --region="${REGION}" \
  --format="get(detailedStatus)"; then
  echo "Unable to retrieve status for tunnel ${TUNNEL_NAME}."
fi
printf '\n'

printf '4️⃣  Tunnel Configuration\n---\n'
if ! gcloud compute vpn-tunnels describe "${TUNNEL_NAME}" \
  --region="${REGION}" \
  --format="yaml(name,peerIp,localTrafficSelector,remoteTrafficSelector,status,detailedStatus)"; then
  echo "Unable to describe tunnel ${TUNNEL_NAME}."
fi
printf '\n'

printf '5️⃣  VPN Routes\n---\n'
if ! gcloud compute routes list \
  --filter="name~${ROUTE_FILTER}" \
  --format="table(name,destRange,nextHopVpnTunnel,priority)"; then
  echo "Unable to list VPN routes with filter 'name~${ROUTE_FILTER}'."
fi
printf '\n'

printf '6️⃣  Firewall Rules\n---\n'
if ! gcloud compute firewall-rules list \
  --filter="name~${FIREWALL_FILTER}" \
  --format="table(name,direction,sourceRanges,destinationRanges,allowed[].map().firewall_rule().list())"; then
  echo "Unable to list firewall rules with filter 'name~${FIREWALL_FILTER}'."
fi
printf '\n'

printf '7️⃣  Recent Gateway Logs (last 10 entries)\n---\n'
if ! gcloud logging read "${LOG_RESOURCE_FILTER}" \
  --limit=10 \
  --format="table(timestamp,severity,jsonPayload.event_type,jsonPayload.event_subtype)"; then
  echo "No logs available or insufficient permissions for filter '${LOG_RESOURCE_FILTER}'."
fi
printf '\n'

echo "✅ Verification complete."
echo "If the tunnel shows 'Waiting for full configuration', coordinate with your partner to activate their side."
