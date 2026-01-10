#!/bin/bash
# Utility script to copy Grafana dashboards to observability host
# Run from bastion or any host with access to observability node

set -euo pipefail

OBSERVABILITY_HOST="${1:-observability}"
DASHBOARD_DIR="/var/lib/grafana/dashboards"
LOCAL_DIR="$(dirname "$0")/../../configs/grafana/dashboards"

echo "Copying dashboards to $OBSERVABILITY_HOST:$DASHBOARD_DIR"

# Create directory if needed
ssh "$OBSERVABILITY_HOST" "sudo mkdir -p $DASHBOARD_DIR && sudo chown grafana:grafana $DASHBOARD_DIR"

# Copy dashboards
for dashboard in "$LOCAL_DIR"/*.json; do
    if [[ -f "$dashboard" ]]; then
        filename=$(basename "$dashboard")
        echo "  Copying $filename..."
        scp "$dashboard" "$OBSERVABILITY_HOST:/tmp/$filename"
        ssh "$OBSERVABILITY_HOST" "sudo mv /tmp/$filename $DASHBOARD_DIR/ && sudo chown grafana:grafana $DASHBOARD_DIR/$filename"
    fi
done

# Restart Grafana to pick up changes
ssh "$OBSERVABILITY_HOST" "sudo systemctl restart grafana-server"

echo "Done! Dashboards deployed and Grafana restarted."
