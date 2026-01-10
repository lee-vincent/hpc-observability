# Operations Guide

## Acceptance Tests

### 1. Slurm Cluster Verification

```bash
# SSH to controller (via bastion or SSM)
aws ssm start-session --target <controller-instance-id>

# Check cluster status
sinfo
# Expected output:
# PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
# gpu*         up   infinite      2   idle compute-[xxx,yyy]

# Check node details
scontrol show nodes

# Verify accounting database
sacctmgr show cluster
# Expected: Shows cluster 'hpc-demo'

sacctmgr show assoc
# Expected: Shows associations for root account
```

### 2. GPU Job Submission

```bash
# Submit interactive job requesting GPU
srun -N1 --gres=gpu:1 nvidia-smi
# Expected: Shows T4 GPU info

# Submit batch job
cat > /tmp/gpu-test.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=gpu-test
#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --time=00:05:00

echo "Running on $(hostname)"
nvidia-smi
echo "CUDA devices: $CUDA_VISIBLE_DEVICES"
EOF

sbatch /tmp/gpu-test.sh
# Watch job
squeue
# Check output after completion
cat slurm-<jobid>.out
```

### 3. Accounting Verification

```bash
# After job completes, verify accounting
sacct -j <jobid> --format=JobID,JobName,Partition,AllocCPUS,State,ExitCode,Elapsed
# Expected: Shows completed job with elapsed time

# Cluster utilization report
sreport cluster utilization start=$(date -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)
```

### 4. Observability Verification

```bash
# On observability host or via port forward
# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'
# Expected: All targets show "up"

# Verify specific exporters
curl -s http://localhost:9090/api/v1/query?query=up | jq '.data.result[] | {instance: .metric.instance, value: .value[1]}'

# Check for GPU metrics
curl -s 'http://localhost:9090/api/v1/query?query=DCGM_FI_DEV_GPU_TEMP' | jq '.data.result'
# Expected: Temperature readings from GPU nodes

# Check Slurm metrics
curl -s 'http://localhost:9090/api/v1/query?query=slurm_nodes_total' | jq '.data.result'
```

### 5. Grafana Verification

```bash
# Port forward to Grafana
aws ssm start-session --target <bastion-instance-id> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["<observability-ip>"],"portNumber":["3000"],"localPortNumber":["3000"]}'

# Open browser to http://localhost:3000
# Login: admin / (password from SSM parameter)
# Verify dashboards load:
# - HPC Cluster Overview
# - GPU Metrics Dashboard
# - Slurm Metrics Dashboard
```

### 6. Security Verification

```bash
# Verify compute nodes have no public IPs
aws ec2 describe-instances \
  --filters "Name=tag:Role,Values=compute" \
  --query 'Reservations[].Instances[].{ID:InstanceId,PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress}'
# Expected: PublicIP should be null

# Verify security groups
aws ec2 describe-security-groups \
  --filters "Name=tag:Project,Values=hpc-obs" \
  --query 'SecurityGroups[].{Name:GroupName,Ingress:IpPermissions}'
```

## Troubleshooting

### Slurm Issues

#### Nodes in DOWN state

```bash
# Check node reason
scontrol show node <nodename> | grep Reason

# Common fixes:
# 1. Munge key mismatch
sudo systemctl restart munge
sudo systemctl restart slurmd

# 2. Communication issue - check firewall
sudo ss -tlnp | grep 6818

# 3. Resume node
sudo scontrol update nodename=<nodename> state=resume
```

#### slurmdbd not starting

```bash
# Check logs
sudo journalctl -u slurmdbd -f

# Verify database connection
mysql -h <db-ip> -u slurm -p<password> -e "SHOW DATABASES;"

# Check slurmdbd.conf permissions
ls -la /etc/slurm/slurmdbd.conf
# Should be 600, owned by slurm:slurm
```

#### Jobs stuck in PENDING

```bash
# Check reason
squeue -o "%.18i %.9P %.8j %.8u %.2t %.10M %.6D %R"

# Common reasons:
# - Resources: Not enough nodes/GPUs available
# - Priority: Other jobs have higher priority
# - Dependency: Waiting for other jobs

# Check resource availability
sinfo -N -l
```

### GPU Issues

#### nvidia-smi not working

```bash
# Check if driver is loaded
lsmod | grep nvidia

# If not loaded, reinstall
sudo /opt/hpc-obs/scripts/setup-nvidia.sh

# May need reboot
sudo reboot
```

#### DCGM exporter not showing metrics

```bash
# Check DCGM service
sudo systemctl status nvidia-dcgm
sudo systemctl status dcgm_exporter

# Test DCGM directly
dcgmi discovery -l

# Check exporter endpoint
curl http://localhost:9400/metrics | head
```

### Observability Issues

#### Prometheus targets down

```bash
# Check target connectivity
curl -v http://<target-ip>:9100/metrics

# Check Prometheus config
promtool check config /etc/prometheus/prometheus.yml

# Reload Prometheus config
curl -X POST http://localhost:9090/-/reload
```

#### Grafana dashboards not loading

```bash
# Check Grafana logs
sudo journalctl -u grafana-server -f

# Verify provisioning
ls -la /var/lib/grafana/dashboards/
ls -la /etc/grafana/provisioning/

# Restart Grafana
sudo systemctl restart grafana-server
```

### Database Issues

#### MariaDB connection refused

```bash
# Check MariaDB status
sudo systemctl status mariadb

# Check bind address
grep bind-address /etc/mysql/mariadb.conf.d/*.cnf

# Test local connection
mysql -u root -e "SELECT 1"

# Check remote access
mysql -h <db-ip> -u slurm -p
```

## Common Operations

### Adding New Compute Nodes

Compute nodes auto-register via cloud-init. To manually add:

```bash
# On controller
scontrol update nodename=<nodename> state=resume

# Or edit slurm.conf and reconfigure
sudo vim /etc/slurm/slurm.conf
sudo scontrol reconfigure
```

### Draining Nodes for Maintenance

```bash
# Drain node (finish current jobs, accept no new)
sudo scontrol update nodename=<nodename> state=drain reason="maintenance"

# After maintenance, resume
sudo scontrol update nodename=<nodename> state=resume
```

### Updating Slurm Configuration

```bash
# Edit config
sudo vim /etc/slurm/slurm.conf

# Distribute to all nodes (or use shared storage)
for node in $(sinfo -h -N -o "%N"); do
  scp /etc/slurm/slurm.conf $node:/etc/slurm/
done

# Reconfigure cluster
sudo scontrol reconfigure
```

### Viewing Logs

```bash
# Slurm controller
sudo tail -f /var/log/slurm/slurmctld.log

# Slurm accounting
sudo tail -f /var/log/slurm/slurmdbd.log

# Compute node
sudo tail -f /var/log/slurm/slurmd.log

# Prometheus
sudo journalctl -u prometheus -f

# Grafana
sudo journalctl -u grafana-server -f

# Cloud-init (initial setup)
sudo tail -f /var/log/cloud-init-output.log
sudo cat /var/log/demo-setup/*.log
```

### Backup Procedures

```bash
# Backup Slurm state
sudo cp -r /var/spool/slurm/ctld /backup/slurm-state-$(date +%Y%m%d)

# Backup MariaDB
mysqldump -h <db-ip> -u slurm -p slurm_acct_db > /backup/slurm_acct_$(date +%Y%m%d).sql

# Backup Prometheus data (if needed)
# Note: Default retention is 30 days
sudo cp -r /var/lib/prometheus /backup/prometheus-$(date +%Y%m%d)
```

## Teardown

### Complete Teardown

```bash
cd terraform
terraform destroy -auto-approve
```

### Partial Teardown (Keep VPC)

```bash
# Scale down compute
terraform apply -var="compute_node_count=0"

# Or target specific resources
terraform destroy -target=module.compute_asg
```

### Manual Cleanup (if Terraform fails)

```bash
# List resources
aws ec2 describe-instances --filters "Name=tag:Project,Values=hpc-obs"

# Terminate instances
aws ec2 terminate-instances --instance-ids <ids>

# Delete ASG
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name hpc-obs-demo-compute-asg --force-delete

# Clean up VPC (after instances terminated)
# Delete NAT Gateway, Internet Gateway, Subnets, then VPC
```
