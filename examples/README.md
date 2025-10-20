# Examples

This directory contains runnable usage scenarios for the `terraform-gcp-vpn` module.
They are intentionally minimal and focus on a single feature combination. Treat them as starting points, not prescriptive production blueprints.

| Scenario | Purpose | Key Flags |
|----------|---------|-----------|
| `minimal` | Basic always-on remote access VPN | `enable_scheduling = false`, `enable_site_to_site_vpn = false` |
| `with-scheduler` | Cost-optimized VPN that powers down outside business hours | `enable_scheduling = true` |
| `site-to-site` | Adds a classic policy-based IPsec tunnel to a partner | `enable_site_to_site_vpn = true` |

General workflow inside any example:

```bash
terraform init
terraform plan
terraform apply
# ... later
terraform destroy
```

Costs: These examples create billable resources (VM, static IP, NAT, etc.). Destroy when finished.

Auto-generated docs (inputs/outputs) will appear in per-example README files once pre-commit hooks are added.
