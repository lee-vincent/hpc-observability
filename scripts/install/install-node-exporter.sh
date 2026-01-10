#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/demo-setup/node-exporter-install.log"
mkdir -p /var/log/demo-setup
exec > >(tee -a "$LOG_FILE") 2>&1

MARKER_FILE="/usr/local/bin/.node-exporter-installed"
NODE_EXPORTER_VERSION="${1:-1.7.0}"

if [[ -f "$MARKER_FILE" ]]; then
    echo "Node exporter already installed"
    exit 0
fi

echo "=== Installing Node Exporter v${NODE_EXPORTER_VERSION} at $(date) ==="

cd /tmp
wget -q "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
tar xzf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
cp "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/

# Create user
useradd --no-create-home --shell /bin/false node_exporter 2>/dev/null || true
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create systemd service
cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Prometheus Node Exporter
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter \
    --web.listen-address=:9100 \
    --collector.systemd \
    --collector.processes
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

touch "$MARKER_FILE"
echo "=== Node Exporter installation completed at $(date) ==="
