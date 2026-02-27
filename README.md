# Tech Summit VAI Live — NIOS Grid Infrastructure

Terraform and Python scripts for the **Tech Summit VAI Live** Instruqt lab. Deploys two independent **Infoblox NIOS Grid Masters** across two AWS regions (`eu-central-1` and `us-east-1`), registered to the same CSP tenant.

## Architecture

```
AWS VPC: 10.100.0.0/16 (eu-central-1)
├── Public Subnet:   10.100.0.0/24 (eu-central-1a)
└── Public Subnet B: 10.100.1.0/24 (eu-central-1b)

10.100.0.10   →  NIOS Grid Master 1 (MGMT)  (m5.2xlarge, AMI-based)
10.100.0.11   →  NIOS Grid Master 1 (LAN1)

AWS VPC: 10.200.0.0/24 (us-east-1)
└── Public Subnet: 10.200.0.0/24

10.200.0.10   →  NIOS Grid Master 2 (MGMT)  (m5.2xlarge, AMI-based)
10.200.0.11   →  NIOS Grid Master 2 (LAN1)
```

## Components

| Component | Region | Description |
|-----------|--------|-------------|
| **NIOS Grid Master 1** | eu-central-1 | Traditional Infoblox appliance with dual NICs (MGMT + LAN1) |
| **NIOS Grid Master 2** | us-east-1 | Second independent NIOS grid with dual NICs (MGMT + LAN1) |

## Repository Structure

```
├── providers.tf         # AWS dual-region providers (eu-central-1 + us-east-1)
├── variables.tf         # Region, VPC CIDR, admin password
├── main.tf              # VPC, subnets, IGW, SGs, TLS key pair, GM1
├── gm2.tf              # VPC, subnet, IGW, SG, GM2 (us-east-1)
├── outputs.tf           # GM1 and GM2 public IPs
└── scripts/
    ├── sandbox_api.py                 # CSP sandbox API client
    ├── create_sandbox.py              # Create Infoblox CSP sandbox
    ├── create_user.py                 # Create CSP user
    ├── deploy_api_key.py              # Generate and export API key
    ├── infoblox_create_join_token.py  # Generate NIOS-X join token
    ├── delete_sandbox.py              # Delete CSP sandbox
    ├── delete_user.py                 # Delete CSP user
    ├── setup_dns.py                   # Create DNS A records
    ├── cleanup_dns_records.py         # Delete DNS records
    ├── deploy_dns_zones.py            # Deploy DNS zones
    ├── deploy_ipam_data.py            # Deploy IPAM data
    ├── enable_nios_management.py      # Enable NIOS management via CSP
    ├── set_csp_join_token.py          # Set CSP join token on NIOS
    └── winrm-init.ps1.tpl            # Windows user_data template
```

## Required Variables

| Variable | Description |
|----------|-------------|
| `windows_admin_password` | NIOS admin password (sensitive) |

## Required Environment Variables (for Python scripts)

| Variable | Description |
|----------|-------------|
| `Infoblox_Token` | CSP API token |
| `INFOBLOX_EMAIL` | CSP login email |
| `INFOBLOX_PASSWORD` | CSP login password |
| `INSTRUQT_PARTICIPANT_ID` | Instruqt participant ID |
| `INSTRUQT_EMAIL` | Participant email |
| `DEMO_AWS_ACCESS_KEY_ID` | AWS key for Route 53 DNS management |
| `DEMO_AWS_SECRET_ACCESS_KEY` | AWS secret for Route 53 DNS management |
| `DEMO_HOSTED_ZONE_ID` | Route 53 hosted zone ID |
| `GM_IP` | NIOS Grid Master 1 public IP |
| `GM2_IP` | NIOS Grid Master 2 public IP |

## Usage

```bash
# Deploy infrastructure
terraform init
terraform apply -auto-approve

# Run Python scripts to create sandbox, user, API key
cd scripts/
python3 create_sandbox.py
python3 create_user.py
python3 deploy_api_key.py
source ~/.bashrc
cd ..
```

## Access

| Resource | URL/Command | Credentials |
|----------|-------------|-------------|
| NIOS Grid Master 1 UI | `https://<GM1_PUBLIC_IP>` | admin / (set via variable) |
| NIOS Grid Master 2 UI | `https://<GM2_PUBLIC_IP>` | admin / (set via variable) |
| Infoblox Portal | https://csp.infoblox.com | CSP credentials |
