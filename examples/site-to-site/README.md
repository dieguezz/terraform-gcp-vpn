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
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 5.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpn"></a> [vpn](#module\_vpn) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_firezone_admin_email"></a> [firezone\_admin\_email](#input\_firezone\_admin\_email) | n/a | `string` | n/a | yes |
| <a name="input_firezone_domain"></a> [firezone\_domain](#input\_firezone\_domain) | n/a | `string` | n/a | yes |
| <a name="input_google_workspace_domain"></a> [google\_workspace\_domain](#input\_google\_workspace\_domain) | n/a | `string` | n/a | yes |
| <a name="input_partner_local_selectors"></a> [partner\_local\_selectors](#input\_partner\_local\_selectors) | n/a | `list(string)` | n/a | yes |
| <a name="input_partner_peer_ip"></a> [partner\_peer\_ip](#input\_partner\_peer\_ip) | n/a | `string` | n/a | yes |
| <a name="input_partner_peer_name"></a> [partner\_peer\_name](#input\_partner\_peer\_name) | n/a | `string` | n/a | yes |
| <a name="input_partner_remote_selectors"></a> [partner\_remote\_selectors](#input\_partner\_remote\_selectors) | n/a | `list(string)` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | n/a | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tunnel_configuration_summary"></a> [tunnel\_configuration\_summary](#output\_tunnel\_configuration\_summary) | Connection info plus partner tunnel setup |
<!-- END_TF_DOCS -->
