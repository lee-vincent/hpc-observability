#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/demo-setup/dcgm-exporter-install.log"
mkdir -p /var/log/demo-setup
exec > >(tee -a "$LOG_FILE") 2>&1

MARKER_FILE="/usr/local/bin/.dcgm-exporter-installed"

if [[ -f "$MARKER_FILE" ]]; then
    echo "DCGM exporter already installed"
    exit 0
fi

echo "=== Installing DCGM Exporter at $(date) ==="

# Verify NVIDIA driver is loaded
if ! nvidia-smi &>/dev/null; then
    echo "ERROR: NVIDIA driver not available. Please install NVIDIA drivers first."
    exit 1
fi

# Ensure DCGM is installed
if ! command -v nv-hostengine &>/dev/null; then
    echo "Installing DCGM..."
    apt-get update
    apt-get install -y datacenter-gpu-manager
fi

# Enable and start DCGM
systemctl enable nvidia-dcgm
systemctl start nvidia-dcgm

# Try to install pre-built dcgm-exporter
cd /tmp
DCGM_EXPORTER_VERSION="3.3.0-3.2.0"

# Try downloading release binary first
if wget -q "https://github.com/NVIDIA/dcgm-exporter/releases/download/v${DCGM_EXPORTER_VERSION}/dcgm-exporter_${DCGM_EXPORTER_VERSION}_amd64.deb" 2>/dev/null; then
    dpkg -i "dcgm-exporter_${DCGM_EXPORTER_VERSION}_amd64.deb" || apt-get install -f -y
else
    echo "Pre-built package not found, building from source..."
    
    # Install Go if not present
    if ! command -v go &>/dev/null; then
        GO_VERSION="1.21.5"
        wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
        rm -rf /usr/local/go
        tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
    fi
    
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=/tmp/go
    
    apt-get install -y git
    
    rm -rf dcgm-exporter
    git clone https://github.com/NVIDIA/dcgm-exporter.git
    cd dcgm-exporter
    make binary
    cp dcgm-exporter /usr/bin/
fi

# Create systemd service
cat > /etc/systemd/system/dcgm_exporter.service << 'EOF'
[Unit]
Description=NVIDIA DCGM Exporter
After=network-online.target nvidia-dcgm.service
Wants=network-online.target nvidia-dcgm.service

[Service]
Type=simple
ExecStart=/usr/bin/dcgm-exporter --address :9400
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable dcgm_exporter
systemctl start dcgm_exporter

touch "$MARKER_FILE"
echo "=== DCGM Exporter installation completed at $(date) ==="
