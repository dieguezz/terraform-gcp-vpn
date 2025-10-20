# Network Module

## Overview
Creates the foundational network infrastructure for the VPN setup. Provisions VPC, subnets, Cloud NAT, Cloud Router, and static IP addresses.

## Architecture

```mermaid
graph TB
    Internet((Internet))
    
    subgraph Network Module
        VPC[VPC Network<br/>Custom Mode]
        Subnet[Subnet<br/>10.148.151.0/27<br/>Private IP Range]
        Router[Cloud Router<br/>BGP Enabled]
        NAT[Cloud NAT<br/>Outbound Only]
        IP1[Static IP<br/>VPN Gateway]
        IP2[Static IP<br/>Firezone VM]
    end
    
    subgraph Attached Resources
        VM[Firezone VM]
        Gateway[VPN Gateway]
    end
    
    Internet <-->|inbound| IP1
    Internet <-->|inbound| IP2
    IP1 -.-> Gateway
    IP2 -.-> VM
    Gateway --> VPC
    VM --> Subnet
    Subnet --> VPC
    VPC --> Router
    Router --> NAT
    NAT -->|outbound only| Internet
    
    classDef networkResource fill:#34a853,stroke:#188038,color:#fff
    classDef ipResource fill:#4285f4,stroke:#1967d2,color:#fff
    
    class VPC,Subnet,Router,NAT networkResource
    class IP1,IP2 ipResource
```

## Resources Created
- **VPC Network**: Custom VPC for VPN infrastructure
- **Subnet**: Regional subnet with private IP range
- **Cloud Router**: BGP router for dynamic routing
- **Cloud NAT**: Outbound internet access for private instances
- **Static IPs**: External IPs for VPN gateway and Firezone

## Key Inputs
- `project_id`: GCP project ID
- `region`: GCP region
- `network_name`: VPC network name
- `subnet_name`: Subnet name
- `subnet_cidr`: IP range for subnet (CIDR notation)
- `nat_name`: Cloud NAT name
- `router_name`: Cloud Router name

## Key Outputs
- `network_id`: VPC network identifier
- `network_name`: VPC network name
- `subnet_id`: Subnet identifier
- `vpn_gateway_ip`: Static IP for VPN gateway
- `firezone_ip`: Static IP for Firezone instance
- `router_name`: Cloud Router name

## References

- [GCP VPC Networks](https://cloud.google.com/vpc/docs/vpc)
- [Terraform google_compute_network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network)
- [Cloud NAT Documentation](https://cloud.google.com/nat/docs/overview)
- [Cloud Router Documentation](https://cloud.google.com/network-connectivity/docs/router)
- [Static IP Addresses](https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address)
