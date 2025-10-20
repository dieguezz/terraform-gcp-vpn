# Minimal Remote Access VPN

Single Firezone instance for remote access. No scheduling, no site-to-site.

> Costs money: VM, static IP, NAT. Destroy when done.

## Usage

```bash
terraform init
terraform apply
```

Set required input variables in `terraform.tfvars` or environment.

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
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | n/a | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_portal"></a> [admin\_portal](#output\_admin\_portal) | Firezone admin portal URL |
<!-- END_TF_DOCS -->
