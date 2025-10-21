# Network Module

## Overview
Creates the foundational network infrastructure for the VPN setup. Provisions VPC, subnets, Cloud NAT, Cloud Router, and static IP addresses.

## Architecture

```mermaid
flowchart LR
    %% External consumers of the network
    subgraph External["External consumers"]
        FirezoneVM["Firezone VM<br/>(compute module)"]
        ClassicVPN["Classic Cloud VPN<br/>(vpn-gateway module)"]
        RemoteUsers["WireGuard clients"]
        PartnerNetworks["Partner networks"]
        PublicInternet["Public internet"]
    end

    %% Network resources managed by this module
    subgraph NetworkModule["module: network"]
        VPC["VPC vpn-vpc<br/>custom mode"]
        SiteToSiteSubnet["Subnet site-to-site<br/>10.200.0.0/24"]
        CloudRouter["Cloud Router"]
        CloudNAT["Cloud NAT gateway"]
        StaticIngressIP["Static IP (ingress)<br/>(example 198.51.100.10)"]
        StaticEgressIP["Static IP (egress)<br/>(example 198.51.100.20)"]
        FlowLogs["VPC Flow Logs"]
    end

    %% Connectivity relationships
    RemoteUsers -- "UDP 51820 via NLB" --> StaticIngressIP
    FirezoneVM <-- "primary NIC" --> SiteToSiteSubnet
    ClassicVPN <-- "tunnels" --> VPC
    PartnerNetworks -- "IPsec" --> ClassicVPN
    SiteToSiteSubnet --> VPC
    VPC --> CloudRouter
    CloudRouter --> CloudNAT
    FirezoneVM -- "egress" --> CloudNAT
    CloudNAT -- "SNAT" --> StaticEgressIP
    StaticEgressIP -- "outbound traffic" --> PublicInternet
    FlowLogs -- "publishes logs" --> VPC

    %% Styling
    classDef network fill:#34a853,stroke:#0c8040,color:#ffffff;
    classDef external fill:#f8f9fa,stroke:#5f6368,color:#202124;
    classDef control fill:#1a73e8,stroke:#174ea6,color:#ffffff;

    class VPC,SiteToSiteSubnet,CloudRouter,CloudNAT,StaticIngressIP,StaticEgressIP,FlowLogs network;
    class FirezoneVM,ClassicVPN,RemoteUsers,PartnerNetworks,PublicInternet external;
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
