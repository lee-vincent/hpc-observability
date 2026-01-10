# HPC Observability Demo - AWS Infrastructure

Complete, runnable AWS demo environment for HPC workloads with:
- **NVIDIA Base Command Manager (BCM)** infrastructure
- **Slurm** workload manager with accounting database
- **GPU compute nodes** (g4dn.xlarge with NVIDIA T4)
- **Observability stack**: Prometheus, Grafana, Alertmanager
- **Metrics exporters**: node_exporter, dcgm-exporter, slurm_exporter

## Requirements

- AWS account with appropriate permissions
- Terraform >= 1.5.0
- AWS CLI configured
- Sufficient quotas for g4dn instances

## Quick Start

```bash
# Clone and enter directory
cd hpc-observability

# Initialize and deploy
cd terraform
terraform init
terraform apply -var='allowed_cidr=["YOUR_IP/32"]'

# Access Grafana via SSM port forward
aws ssm start-session --target $(terraform output -raw bastion_instance_id) \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["'$(terraform output -raw observability_private_ip)'"],"portNumber":["3000"],"localPortNumber":["3000"]}'
```

Open http://localhost:3000 (admin / password from SSM parameter)

## Repository Structure

```
hpc-observability/
├── terraform/                   # Infrastructure as Code
│   ├── main.tf                  # Main configuration
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Output values
│   ├── providers.tf             # Provider configuration
│   ├── versions.tf              # Version constraints
│   └── modules/
│       ├── vpc/                 # VPC, subnets, NAT
│       ├── security/            # Security groups
│       ├── iam/                 # IAM roles and policies
│       ├── instances/           # EC2 instances
│       └── asg/                 # Auto Scaling Group for compute
├── scripts/
│   ├── cloud-init/              # Cloud-init templates per role
│   │   ├── bastion.yaml
│   │   ├── bcm.yaml
│   │   ├── controller.yaml
│   │   ├── db.yaml
│   │   ├── compute.yaml
│   │   └── observability.yaml
│   └── install/                 # Standalone install scripts
│       ├── install-node-exporter.sh
│       ├── install-dcgm-exporter.sh
│       └── install-slurm-exporter.sh
├── configs/
│   ├── slurm/                   # Slurm configuration templates
│   ├── prometheus/              # Prometheus configuration
│   ├── grafana/
│   │   └── dashboards/          # Pre-built Grafana dashboards
│   └── systemd/                 # Systemd unit files
└── runbook/
    ├── README.md                # Quick start guide
    ├── operations.md            # Operations and troubleshooting
    └── costs.md                 # Cost estimation and optimization
```

## Architecture

| Host | Role | Instance Type | Purpose |
|------|------|---------------|---------|
| bastion | Admin | t3.small | SSM/SSH jump host |
| bcm | BCM Head | t3.large | NVIDIA BCM infrastructure |
| controller | Slurm | t3.large | slurmctld, slurmdbd |
| db | Database | t3.medium | MariaDB accounting |
| observability | Monitoring | t3.large | Prometheus, Grafana |
| compute-* | GPU Workers | g4dn.xlarge | slurmd, GPU workloads |

## Features

### Security
- Private subnets for all workloads
- SSM Session Manager (no SSH keys required)
- Least-privilege IAM roles
- Secrets in SSM Parameter Store

### Observability
- Prometheus with EC2 service discovery
- Pre-configured Grafana dashboards
- GPU metrics via DCGM exporter
- Slurm metrics via prometheus-slurm-exporter
- Alert rules for common failure scenarios

### Slurm
- Full accounting database (MariaDB)
- GPU scheduling support (GRES)
- Auto-registering compute nodes

## Documentation

- [Quick Start](runbook/README.md)
- [Operations Guide](runbook/operations.md)
- [Cost Estimation](runbook/costs.md)

## Customization

See `terraform/variables.tf` for all configurable options:

```hcl
# terraform.tfvars
region                = "us-west-2"
compute_instance_type = "g5.xlarge"
compute_node_count    = 4
enable_spot_instances = true
```

## Cleanup

```bash
terraform destroy
```

## License

Infrastructure code provided as-is. NVIDIA BCM requires separate enterprise licensing.
