# HPC Observability Demo Environment

A complete, runnable AWS demo environment with NVIDIA Base Command Manager (BCM) infrastructure, Slurm workload manager with accounting, GPU compute nodes, and a full observability stack (Prometheus + Grafana).

## Quick Start

### Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.5.0
3. **SSH key pair** in AWS (optional if using SSM)
4. Sufficient AWS quotas for g4dn instances

### One-Command Deployment

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan -var="allowed_cidr=[\"YOUR_IP/32\"]"

# Deploy (takes ~15-20 minutes)
terraform apply -var="allowed_cidr=[\"YOUR_IP/32\"]"
```

### Minimal Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | us-east-1 | AWS region |
| `allowed_cidr` | ["0.0.0.0/0"] | **Change this** to your IP for security |
| `compute_node_count` | 2 | Number of GPU compute nodes |
| `use_ssm` | true | Use SSM Session Manager (recommended) |

### Access the Environment

After deployment completes, Terraform outputs access instructions:

```bash
# Get outputs
terraform output

# Connect to bastion via SSM
aws ssm start-session --target $(terraform output -raw bastion_instance_id)

# Port forward to Grafana
aws ssm start-session --target $(terraform output -raw bastion_instance_id) \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["'$(terraform output -raw observability_private_ip)'"],"portNumber":["3000"],"localPortNumber":["3000"]}'
```

Then open http://localhost:3000 (Grafana: admin / check SSM parameter)

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                              VPC                                     │
│  ┌──────────────────┐    ┌────────────────────────────────────────┐ │
│  │  Public Subnet   │    │           Private Subnet                │ │
│  │                  │    │                                          │ │
│  │  ┌────────────┐  │    │  ┌─────────┐  ┌────────────┐            │ │
│  │  │  Bastion   │  │    │  │   BCM   │  │ Controller │            │ │
│  │  │  (SSM)     │──┼────┼──│  Head   │  │  (Slurm)   │            │ │
│  │  └────────────┘  │    │  └─────────┘  └────────────┘            │ │
│  │        │         │    │        │            │                    │ │
│  │        │         │    │  ┌─────┴────────────┴─────┐             │ │
│  │   NAT Gateway    │    │  │                        │             │ │
│  │        │         │    │  │  ┌──────┐  ┌──────┐   │             │ │
│  └────────┼─────────┘    │  │  │ DB   │  │ Obs  │   │             │ │
│           │              │  │  │(Maria)│  │(Prom/│   │             │ │
│           │              │  │  └──────┘  │Grafana)   │             │ │
│           │              │  │            └──────┘   │             │ │
│           │              │  │                        │             │ │
│           │              │  │  ┌─────────────────┐  │             │ │
│           │              │  │  │  Compute ASG    │  │             │ │
│           │              │  │  │  ┌────┐ ┌────┐  │  │             │ │
│           │              │  │  │  │GPU │ │GPU │  │  │             │ │
│           │              │  │  │  │Node│ │Node│  │  │             │ │
│           │              │  │  │  └────┘ └────┘  │  │             │ │
│           │              │  │  └─────────────────┘  │             │ │
│           │              │  └────────────────────────┘             │ │
│           │              └────────────────────────────────────────┘ │
└───────────┼─────────────────────────────────────────────────────────┘
            │
       Internet Gateway
```

## Components

### Hosts

| Host | Role | Instance Type | Purpose |
|------|------|---------------|---------|
| bastion | Admin access | t3.small | SSH/SSM jump host |
| bcm | BCM Head | t3.large | NVIDIA BCM infrastructure |
| controller | Slurm Controller | t3.large | slurmctld, slurmdbd, slurm_exporter |
| db | Database | t3.medium | MariaDB for Slurm accounting |
| observability | Monitoring | t3.large | Prometheus, Grafana, Alertmanager |
| compute-* | GPU Workers | g4dn.xlarge | slurmd, node_exporter, dcgm_exporter |

### Software Stack

- **OS**: Ubuntu 22.04 LTS
- **Slurm**: 23.11.10 (built from source)
- **MariaDB**: Latest from Ubuntu repos
- **Prometheus**: 2.48.0
- **Grafana**: Latest OSS
- **Alertmanager**: 0.26.0
- **NVIDIA Driver**: 535 (for T4)
- **DCGM**: Latest from NVIDIA repos

## Verification

See [operations.md](operations.md) for detailed acceptance tests.

### Quick Checks

```bash
# On controller - check Slurm
sinfo                           # Show node status
squeue                          # Show job queue
sacctmgr show cluster           # Verify accounting

# Submit test job
srun -N1 --gres=gpu:1 nvidia-smi

# Check observability
curl http://observability:9090/api/v1/targets  # Prometheus targets
curl http://observability:3000/api/health      # Grafana health
```

## Customization

### Using Different GPU Instance Types

```hcl
# terraform.tfvars
compute_instance_type = "g5.xlarge"  # A10G instead of T4
compute_node_count    = 4
```

### Using Spot Instances

```hcl
enable_spot_instances = true
spot_max_price        = "0.50"  # Max hourly price
```

### Scaling Compute Nodes

```bash
# Scale via Terraform
terraform apply -var="compute_node_count=4"

# Or via AWS CLI
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name hpc-obs-demo-compute-asg \
  --desired-capacity 4
```

## Teardown

```bash
cd terraform
terraform destroy
```

**Note**: All resources will be deleted including EBS volumes.

## Known Limitations

1. **BCM License Required**: BCM software requires NVIDIA enterprise license. The infrastructure is provisioned but BCM installation requires manual completion with license.

2. **Single AZ**: Demo uses single availability zone for simplicity.

3. **No HA**: Slurm controller and database are single instances.

4. **Self-signed Certificates**: BCM UI uses self-signed SSL.

## Support

For issues with this demo:
1. Check `/var/log/demo-setup/*.log` on relevant hosts
2. Review cloud-init logs: `/var/log/cloud-init-output.log`
3. Check systemd service status: `systemctl status <service>`

## License

This demo infrastructure code is provided as-is. NVIDIA BCM requires separate licensing.
