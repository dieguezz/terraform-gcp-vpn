# tfsec Notes

We run `tfsec` through pre-commit to catch security misconfigurations early.

Current expectations:
1. Allow firewall ingress for WireGuard UDP port and HTTPS (443). These are intentional exposures.
2. OS Login is enabled; SSH CIDR restricted to IAP by default.
3. Secret Manager stores preshared keys for VPN tunnels; ensure no hard-coded secrets in `.tf` files.
4. Flow logs and NAT logging are enabled to improve auditability.

If a finding is a false positive:
- Prefer remediation over ignoring.
- If ignoring, annotate with inline `#tfsec:ignore:<RULE>` and open an issue to revisit.

Pipeline will fail on new HIGH/CRITICAL severities unless explicitly justified.
