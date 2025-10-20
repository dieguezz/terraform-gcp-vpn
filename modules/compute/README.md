# Compute Module

## Overview
Creates and configures the Firezone VPN server VM instance with WireGuard support. Handles instance setup, metadata configuration, and startup script execution.

## Architecture

```mermaid
graph LR
    subgraph Compute Module
        VM[GCE Instance<br/>Firezone VM<br/>e2-medium]
        Script[Startup Script<br/>firezone-install.sh]
        Meta[Instance Metadata<br/>firezone_token]
    end
    
    subgraph External Dependencies
        SA[Service Account]
        Secret[Secret Manager]
        Network[VPC Network]
        Subnet[Subnet]
        IP[Static External IP]
    end
    
    Script -.->|installs| VM
    Meta -.->|configures| VM
    SA -.->|identity| VM
    Secret -.->|credentials| VM
    Network --> Subnet
    Subnet -.->|network| VM
    IP -.->|public access| VM
    
    classDef computeResource fill:#4285f4,stroke:#1967d2,color:#fff
    classDef externalResource fill:#34a853,stroke:#188038,color:#fff
    
    class VM,Script,Meta computeResource
    class SA,Secret,Network,Subnet,IP externalResource
```

## Resources Created
- **GCE Instance**: Firezone VPN server (e2-medium)
- **Startup Script**: Automated Firezone installation and configuration
- **Service Account Binding**: IAM permissions for Secret Manager access

## Key Inputs
- `instance_name`: VM instance name
- `machine_type`: Instance size (default: e2-medium)
- `zone`: GCP zone for deployment
- `network_id`: VPC network ID
- `subnet_id`: Subnet ID for instance
- `external_ip`: Static external IP address
- `service_account_email`: Service account for instance
- `firezone_token`: Installation token for Firezone
- `secret_id`: Secret Manager secret ID for credentials

## Key Outputs
- `instance_id`: VM instance identifier
- `instance_name`: VM instance name
- `internal_ip`: Private IP address
- `external_ip`: Public IP address

## References

- [GCP Compute Engine Documentation](https://cloud.google.com/compute/docs)
- [Terraform google_compute_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance)
- [Firezone Installation Guide](https://www.firezone.dev/docs/deploy)
- [GCP Secret Manager Access](https://cloud.google.com/secret-manager/docs/access-control)
