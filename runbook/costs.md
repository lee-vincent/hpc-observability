# Cost Estimation and Optimization

## Estimated Monthly Costs (US East - N. Virginia)

### Default Configuration

| Resource | Type | Quantity | Hourly | Monthly (730h) |
|----------|------|----------|--------|----------------|
| Bastion | t3.small | 1 | $0.0208 | $15.18 |
| BCM Head | t3.large | 1 | $0.0832 | $60.74 |
| Controller | t3.large | 1 | $0.0832 | $60.74 |
| Database | t3.medium | 1 | $0.0416 | $30.37 |
| Observability | t3.large | 1 | $0.0832 | $60.74 |
| **Compute (GPU)** | g4dn.xlarge | 2 | $0.526 x 2 | **$768.18** |
| NAT Gateway | - | 1 | $0.045 | $32.85 |
| NAT Data Transfer | - | ~50GB | $0.045/GB | ~$2.25 |
| EBS (gp3) | - | ~400GB | $0.08/GB | $32.00 |
| **Total** | | | | **~$1,063/month** |

### Primary Cost Driver: GPU Instances

GPU instances (g4dn.xlarge) account for **~72%** of total costs.

## Cost Reduction Strategies

### 1. Use Spot Instances for Compute (Up to 70% savings)

```hcl
# terraform.tfvars
enable_spot_instances = true
spot_max_price        = "0.20"  # ~60% of on-demand
```

**Savings**: $768 → ~$230/month (g4dn.xlarge spot typically $0.15-0.20/hr)

**Trade-off**: Instances may be terminated with 2-minute warning.

### 2. Scale Down When Not in Use

```bash
# Scale to 0 compute nodes outside working hours
terraform apply -var="compute_node_count=0"

# Or use AWS CLI
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name hpc-obs-demo-compute-asg \
  --desired-capacity 0
```

**Savings**: Running only 8 hours/day = **~67% savings** on compute

### 3. Use Smaller Instance Types for Non-GPU Hosts

```hcl
# terraform.tfvars
bastion_instance_type       = "t3.micro"      # $0.0104/hr
bcm_instance_type           = "t3.medium"     # $0.0416/hr
controller_instance_type    = "t3.medium"     # $0.0416/hr
db_instance_type            = "t3.small"      # $0.0208/hr
observability_instance_type = "t3.medium"     # $0.0416/hr
```

**Savings**: ~$100/month on management hosts

### 4. Replace NAT Gateway with NAT Instance

NAT Gateway costs ~$32/month + data processing. A t3.nano NAT instance costs ~$4/month.

**Not implemented in this demo**, but documented for production consideration.

### 5. Use Reserved Instances for Long-Running Workloads

For 1-year commitment:
- t3.large: ~40% savings
- g4dn.xlarge: ~30% savings

### 6. Use Savings Plans

Compute Savings Plans provide flexibility across instance types with similar discounts to Reserved Instances.

## Minimal Demo Configuration

For testing/demo with minimal cost:

```hcl
# terraform.tfvars - Minimal config
region                      = "us-east-1"
bastion_instance_type       = "t3.micro"
bcm_instance_type           = "t3.small"
controller_instance_type    = "t3.small"
db_instance_type            = "t3.micro"
observability_instance_type = "t3.small"
compute_instance_type       = "g4dn.xlarge"
compute_node_count          = 1
enable_spot_instances       = true
spot_max_price              = "0.20"
```

**Estimated cost**: ~$200/month (with spot)

## Cost Monitoring

### Enable AWS Cost Explorer

```bash
# View current month costs by service
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE
```

### Set Budget Alerts

```bash
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget '{
    "BudgetName": "HPC-Demo-Monthly",
    "BudgetLimit": {"Amount": "500", "Unit": "USD"},
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }' \
  --notifications-with-subscribers '[{
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80
    },
    "Subscribers": [{
      "SubscriptionType": "EMAIL",
      "Address": "your-email@example.com"
    }]
  }]'
```

### Tag-Based Cost Allocation

All resources are tagged with:
- `Project=hpc-obs`
- `Environment=demo`

Enable cost allocation tags in AWS Billing to track costs by these tags.

## Data Transfer Costs

| Transfer Type | Cost |
|--------------|------|
| NAT Gateway processing | $0.045/GB |
| Inter-AZ | $0.01/GB each way |
| Internet egress (first 10TB) | $0.09/GB |
| S3 same-region | Free |

**Mitigation**: Use VPC endpoints for S3/SSM to avoid NAT Gateway charges for AWS API calls.

## Storage Costs

| Volume Type | Cost | Notes |
|------------|------|-------|
| gp3 (default) | $0.08/GB/month | 3000 IOPS, 125 MB/s included |
| gp2 | $0.10/GB/month | Legacy, avoid |
| io2 | $0.125/GB/month + IOPS | Only if high IOPS needed |

**Current allocation**:
- Bastion: 20GB
- BCM: 100GB
- Controller: 50GB
- DB: 50GB (gp3 with provisioned IOPS)
- Observability: 100GB
- Compute: 100GB each

## Cleanup Reminder

**To avoid ongoing charges, remember to destroy the environment when done:**

```bash
cd terraform
terraform destroy
```

This removes all resources including:
- EC2 instances
- EBS volumes
- NAT Gateway
- Elastic IPs
- VPC resources
