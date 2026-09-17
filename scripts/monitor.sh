#!/bin/bash

# =================================
# Linux Server Continuous Monitor
# =================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HEALTH_SCRIPT="$SCRIPT_DIR/server-health.sh"

# Check if health script exists
if [ ! -f "$HEALTH_SCRIPT" ]; then
    echo "ERROR: server-health.sh not found!"
    exit 1
fi

echo "================================="
echo "   Linux Server Continuous Monitor"
echo "================================="
echo "Monitoring started..."
echo "Press Ctrl+C to stop."
echo "================================="

while true
do
    "$HEALTH_SCRIPT"

    echo ""
    echo "Next health check in 10 seconds..."
    echo ""

    sleep 10
done
