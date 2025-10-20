# Remote Access + Site-to-Site Tunnel

Extends minimal setup with a single Classic IPsec policy-based tunnel to a partner.

> Costs money: VM, static IP, NAT, Classic VPN gateway & tunnels.

## Usage

Edit `terraform.tfvars` with partner IP and selectors.

```bash
terraform init
terraform apply
```

Share tunnel parameters with the partner for their configuration.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
