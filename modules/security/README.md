# Security Module

## Overview
Manages firewall rules and IAM policies for the VPN infrastructure. Controls network access, defines security perimeter, and grants necessary permissions.

## Architecture

```mermaid
graph TB
    subgraph Internet
        Admin[Admin Users<br/>SSH Access]
        VPNUsers[VPN Users<br/>WireGuard]
        Partner[Partner Gateway<br/>IPsec]
    end
    
    subgraph Security Module
        direction TB
        
        subgraph Firewall Rules
            FW1[SSH Rule<br/>TCP :22<br/>allowed_ssh_cidrs]
            FW2[WireGuard Rule<br/>UDP :51820<br/>0.0.0.0/0]
            FW3[IPsec Rule<br/>UDP :500,:4500<br/>ESP protocol<br/>peer_ip]
            FW4[Egress Rule<br/>Allow All Outbound]
        end
        
        subgraph IAM
            SA[Service Account<br/>Firezone VM Identity]
            Binding[IAM Binding<br/>secretmanager.secretAccessor]
        end
    end
    
    subgraph Protected Resources
        VM[Firezone VM]
        Secrets[Secret Manager]
    end
    
    Admin -->|:22| FW1
    VPNUsers -->|:51820| FW2
    Partner -->|:500,:4500,ESP| FW3
    FW1 -.->|allows| VM
    FW2 -.->|allows| VM
    FW3 -.->|allows| VM
    FW4 -.->|allows| VM
    SA -.->|identity| VM
    Binding -.->|grants access| SA
    SA -.->|reads| Secrets
    
    classDef securityResource fill:#ea4335,stroke:#c5221f,color:#fff
    classDef externalResource fill:#fbbc04,stroke:#f29900,color:#000
    
    class FW1,FW2,FW3,FW4,SA,Binding securityResource
    class Admin,VPNUsers,Partner externalResource
```

## Resources Created
- **Firewall Rules**: Ingress/egress rules for VPN, WireGuard, and management
- **Service Account**: Identity for Firezone VM instance
- **IAM Bindings**: Secret Manager access permissions

## Key Inputs
- `project_id`: GCP project ID
- `network_name`: VPC network name
- `subnet_cidr`: Subnet IP range for internal rules
- `allowed_ssh_cidrs`: IP ranges allowed for SSH access
- `vpn_peer_ip`: Partner VPN gateway IP for IPsec
- `service_account_name`: Service account identifier

## Key Outputs
- `service_account_email`: Service account email address
- `firewall_rule_ids`: List of created firewall rule IDs

## Security Notes
- Restrict `allowed_ssh_cidrs` to trusted IP ranges only
- VPN peer IP is whitelisted for IPsec (UDP 500, 4500, ESP)
- WireGuard port 51820 exposed for remote access VPN

## References

- [GCP Firewall Rules](https://cloud.google.com/firewall/docs/firewalls)
- [Terraform google_compute_firewall](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall)
- [GCP IAM Documentation](https://cloud.google.com/iam/docs)
- [Terraform google_service_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account)
- [VPC Firewall Best Practices](https://cloud.google.com/vpc/docs/firewalls#best_practices)
