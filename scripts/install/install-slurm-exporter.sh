#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/demo-setup/slurm-exporter-install.log"
mkdir -p /var/log/demo-setup
exec > >(tee -a "$LOG_FILE") 2>&1

MARKER_FILE="/usr/local/bin/.slurm-exporter-installed"

if [[ -f "$MARKER_FILE" ]]; then
    echo "Slurm exporter already installed"
    exit 0
fi

echo "=== Installing Slurm Exporter at $(date) ==="

# Install Go if not present
if ! command -v go &>/dev/null; then
    echo "Installing Go..."
    cd /tmp
    GO_VERSION="1.21.5"
    wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
fi

export PATH=$PATH:/usr/local/go/bin
export GOPATH=/tmp/go

# Install git if needed
apt-get update
apt-get install -y git

# Clone and build prometheus-slurm-exporter
cd /tmp
rm -rf prometheus-slurm-exporter
git clone https://github.com/vpenso/prometheus-slurm-exporter.git
cd prometheus-slurm-exporter

# Build
go mod init prometheus-slurm-exporter 2>/dev/null || true
go mod tidy 2>/dev/null || true
go build -o slurm_exporter .

# Install
cp slurm_exporter /usr/local/bin/
chmod +x /usr/local/bin/slurm_exporter

# Create systemd service
cat > /etc/systemd/system/slurm_exporter.service << 'EOF'
[Unit]
Description=Prometheus Slurm Exporter
After=network-online.target slurmctld.service
Wants=network-online.target

[Service]
Type=simple
User=slurm
Group=slurm
ExecStart=/usr/local/bin/slurm_exporter
Restart=always
RestartSec=10
Environment="PATH=/usr/local/bin:/usr/bin:/bin"

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable slurm_exporter
systemctl start slurm_exporter

touch "$MARKER_FILE"
echo "=== Slurm Exporter installation completed at $(date) ==="
