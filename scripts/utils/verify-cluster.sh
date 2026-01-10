#!/bin/bash
# Cluster verification script
# Run on controller node to verify cluster health

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }

echo "=================================="
echo "HPC Cluster Verification"
echo "=================================="
echo ""

# Check Slurm services
echo "=== Slurm Services ==="
if systemctl is-active --quiet slurmctld; then
    pass "slurmctld is running"
else
    fail "slurmctld is NOT running"
fi

if systemctl is-active --quiet slurmdbd; then
    pass "slurmdbd is running"
else
    fail "slurmdbd is NOT running"
fi

if systemctl is-active --quiet munge; then
    pass "munge is running"
else
    fail "munge is NOT running"
fi
echo ""

# Check cluster info
echo "=== Cluster Status ==="
if sinfo &>/dev/null; then
    pass "sinfo works"
    echo "Partitions:"
    sinfo -s
else
    fail "sinfo failed"
fi
echo ""

# Check accounting
echo "=== Accounting ==="
if sacctmgr show cluster -n 2>/dev/null | grep -q .; then
    pass "sacctmgr show cluster works"
    sacctmgr show cluster -n
else
    fail "sacctmgr show cluster failed"
fi
echo ""

# Check node count
echo "=== Nodes ==="
TOTAL_NODES=$(sinfo -h -N -o "%N" 2>/dev/null | wc -l || echo 0)
IDLE_NODES=$(sinfo -h -t idle -N -o "%N" 2>/dev/null | wc -l || echo 0)
DOWN_NODES=$(sinfo -h -t down -N -o "%N" 2>/dev/null | wc -l || echo 0)

echo "Total nodes: $TOTAL_NODES"
echo "Idle nodes: $IDLE_NODES"
echo "Down nodes: $DOWN_NODES"

if [[ $DOWN_NODES -gt 0 ]]; then
    warn "$DOWN_NODES node(s) are down"
    sinfo -t down -N -l
fi
echo ""

# Check Prometheus endpoints (if curl available)
echo "=== Exporters ==="
if command -v curl &>/dev/null; then
    if curl -s localhost:9100/metrics &>/dev/null; then
        pass "node_exporter responding (port 9100)"
    else
        fail "node_exporter not responding"
    fi
    
    if curl -s localhost:9341/metrics &>/dev/null; then
        pass "slurm_exporter responding (port 9341)"
    else
        warn "slurm_exporter not responding (port 9341)"
    fi
else
    warn "curl not available, skipping exporter checks"
fi
echo ""

# Test GPU availability
echo "=== GPU Test ==="
if srun -N1 --gres=gpu:1 -t 1 nvidia-smi &>/dev/null; then
    pass "GPU job runs successfully"
else
    warn "GPU job failed or no GPU nodes available"
fi
echo ""

echo "=================================="
echo "Verification complete"
echo "=================================="
