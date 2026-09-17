#!/bin/bash

# =================================
# Linux Server Report Generator
# =================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."

REPORT_FILE="$PROJECT_DIR/reports/server-report.txt"

# Create reports directory if it does not exist
mkdir -p "$PROJECT_DIR/reports"

echo "Generating server report..."

{
    echo "================================="
    echo "      Linux Server Report"
    echo "================================="
    echo ""
    echo "Generated: $(date)"
    echo ""
    echo "Hostname: $(hostname)"
    echo ""

    # CPU Usage
    CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | \
    awk -F',' '{for(i=1;i<=NF;i++) if($i ~ /id/) print $i}' | \
    awk '{print $1}')

    CPU_USAGE=$(echo "100 - $CPU_IDLE" | bc -l | \
    awk '{printf "%.1f", $1}')

    echo "CPU Usage: ${CPU_USAGE}%"

    # Memory Usage
    MEMORY_USAGE=$(free | awk '/Mem:/ {
        printf "%.1f", ($3/$2)*100
    }')

    echo "Memory Usage: ${MEMORY_USAGE}%"

    # Disk Usage
    DISK_USAGE=$(df / | awk 'NR==2 {
        gsub("%","")
        print $5
    }')

    echo "Disk Usage: ${DISK_USAGE}%"

    # Network
    PING_RESULT=$(ping -c 1 -W 2 google.com 2>/dev/null)

    if [ $? -eq 0 ]; then

        NETWORK_STATUS="CONNECTED"

        NETWORK_LATENCY=$(echo "$PING_RESULT" |
            awk -F'time=' '/time=/{print $2}' |
            awk '{print $1}')

    else

        NETWORK_STATUS="DISCONNECTED"
        NETWORK_LATENCY="N/A"

    fi

    echo "Network Status: $NETWORK_STATUS"
    echo "Network Latency: ${NETWORK_LATENCY} ms"

    # System Health
    if (( $(echo "$CPU_USAGE >= 90" | bc -l) )) || \
       (( $(echo "$MEMORY_USAGE >= 90" | bc -l) )) || \
       (( $(echo "$DISK_USAGE >= 90" | bc -l) )) || \
       [ "$NETWORK_STATUS" = "DISCONNECTED" ]; then

        SYSTEM_STATUS="CRITICAL"

    elif (( $(echo "$CPU_USAGE >= 70" | bc -l) )) || \
         (( $(echo "$MEMORY_USAGE >= 70" | bc -l) )) || \
         (( $(echo "$DISK_USAGE >= 70" | bc -l) )); then

        SYSTEM_STATUS="WARNING"

    else

        SYSTEM_STATUS="HEALTHY"

    fi

    echo "System Status: $SYSTEM_STATUS"

    if [ "$SYSTEM_STATUS" = "HEALTHY" ]; then
        echo "Server is healthy."
    elif [ "$SYSTEM_STATUS" = "WARNING" ]; then
        echo "Server requires attention."
    else
        echo "CRITICAL: Server requires immediate attention."
    fi

    echo ""
echo "Top 5 CPU-consuming processes:"
ps aux --sort=-%cpu | head -n 6

echo ""
echo "Recent Alerts:"

if [ -f "$PROJECT_DIR/logs/alerts.log" ] && [ -s "$PROJECT_DIR/logs/alerts.log" ]; then
    tail -n 5 "$PROJECT_DIR/logs/alerts.log"
else
    echo "No alerts recorded."
fi

echo ""
echo "================================="

} > "$REPORT_FILE"

echo "Report generated successfully!"
echo "Report saved to: $REPORT_FILE"
