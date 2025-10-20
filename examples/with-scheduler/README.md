# VPN with Scheduling

Adds Cloud Scheduler / Functions powered start-stop to reduce cost outside of business hours.

> Costs money: VM (during runtime), static IP, NAT, Cloud Scheduler, Functions invocations.

## Usage

```bash
terraform init
terraform apply
```

Adjust cron expressions in `terraform.tfvars.example`.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
