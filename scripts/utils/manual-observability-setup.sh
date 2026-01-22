#!/bin/bash
# Manual Observability Stack Setup Script
# This script contains all the commands that were successfully tested manually
# on Ubuntu 24.04 for setting up node_exporter, Prometheus, and Grafana.
#
# Usage: Run as root or with sudo on the observability instance
# Prerequisites: Instance must have IAM role with SSM and EC2 describe permissions

set -euo pipefail

echo "=== Observability Stack Manual Setup ==="
echo "Started at $(date)"

# Step 1: Install base packages (awscli not available via apt on Ubuntu 24.04)
echo "=== Step 1: Installing base packages ==="
apt-get update
apt-get install -y jq curl wget apt-transport-https software-properties-common unzip

# Step 2: Install AWS CLI v2 (official installer)
echo "=== Step 2: Installing AWS CLI v2 ==="
cd /tmp
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install || true  # May already be installed
aws --version

# Step 3: Create directories
echo "=== Step 3: Creating directories ==="
mkdir -p /var/log/demo-setup /etc/prometheus/rules /opt/hpc-obs/scripts

# Step 4: Install node_exporter
echo "=== Step 4: Installing node_exporter ==="
NODE_EXPORTER_VERSION="1.7.0"
cd /tmp
wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
useradd --no-create-home --shell /bin/false node_exporter || true
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Step 5: Create node_exporter systemd service
echo "=== Step 5: Creating node_exporter service ==="
tee /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Prometheus Node Exporter
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:9100 --collector.systemd --collector.processes
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter
echo "node_exporter status:"
systemctl status node_exporter --no-pager || true

# Step 6: Install Prometheus
echo "=== Step 6: Installing Prometheus ==="
PROMETHEUS_VERSION="3.5.0"
cd /tmp
wget -q https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar xzf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
useradd --no-create-home --shell /bin/false prometheus || true
mkdir -p /etc/prometheus /var/lib/prometheus
cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus /usr/local/bin/
cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

# Step 7: Create Prometheus config (using IMDSv2 for region)
echo "=== Step 7: Creating Prometheus config ==="
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
echo "Detected AWS Region: $AWS_REGION"

tee /etc/prometheus/prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'hpc-obs'
    environment: 'demo'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    ec2_sd_configs:
      - region: ${AWS_REGION}
        port: 9100
        filters:
          - name: tag:Project
            values: ['hpc-obs']
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name
      - source_labels: [__meta_ec2_tag_Role]
        target_label: role
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: '\${1}:9100'
EOF

chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

# Step 8: Create Prometheus systemd service
echo "=== Step 8: Creating Prometheus service ==="
tee /etc/systemd/system/prometheus.service << 'EOF'
[Unit]
Description=Prometheus Monitoring System
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --web.listen-address=0.0.0.0:9090 \
  --web.enable-lifecycle \
  --storage.tsdb.retention.time=30d
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus
echo "Prometheus status:"
systemctl status prometheus --no-pager || true

# Step 9: Install Grafana
echo "=== Step 9: Installing Grafana ==="
wget -q -O /tmp/grafana.key https://apt.grafana.com/gpg.key
mkdir -p /usr/share/keyrings
cp /tmp/grafana.key /usr/share/keyrings/grafana.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list
apt-get update
apt-get install -y grafana

# Step 10: Configure Grafana
echo "=== Step 10: Configuring Grafana ==="
tee /etc/grafana/grafana.ini << 'EOF'
[server]
http_addr = 0.0.0.0
http_port = 3000

[security]
admin_user = admin
admin_password = admin

[users]
allow_sign_up = false

[auth.anonymous]
enabled = false
EOF

# Step 11: Configure Prometheus datasource for Grafana
echo "=== Step 11: Configuring Prometheus datasource ==="
mkdir -p /etc/grafana/provisioning/datasources
tee /etc/grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    editable: false
EOF

# Step 12: Start Grafana
echo "=== Step 12: Starting Grafana ==="
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server
echo "Grafana status:"
systemctl status grafana-server --no-pager || true

echo ""
echo "=== Setup Complete ==="
echo "Completed at $(date)"
echo ""
echo "Services running:"
echo "  - node_exporter: http://localhost:9100/metrics"
echo "  - Prometheus:    http://localhost:9090"
echo "  - Grafana:       http://localhost:3000 (admin/admin)"
echo ""
echo "To access Grafana via SSM port forwarding from your local machine:"
echo "  aws ssm start-session --target <bastion-instance-id> \\"
echo "    --document-name AWS-StartPortForwardingSessionToRemoteHost \\"
echo "    --parameters '{\"host\":[\"<observability-private-ip>\"],\"portNumber\":[\"3000\"],\"localPortNumber\":[\"3000\"]}'"
echo ""
echo "Then open: http://localhost:3000"
