#!/bin/bash

# Stop the script if an important command fails
set -o pipefail

# =================================
# Linux Server Health Monitor
# =================================

# Project directories
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."

# Configuration
CONFIG_FILE="$PROJECT_DIR/config/monitor.conf"

# Log file
LOG_FILE="$PROJECT_DIR/logs/health.log"


# =================================
# LOAD CONFIGURATION
# =================================

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "ERROR: Configuration file not found!"
    exit 1
fi


# =================================
# SERVER INFORMATION
# =================================

echo "================================="
echo "     Linux Server Health Check"
echo "================================="

echo "Hostname: $(hostname)"
echo "Date: $(date)"

echo "================================="


# =================================
# CPU USAGE
# =================================

CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | \
awk -F',' '{for(i=1;i<=NF;i++) if($i ~ /id/) print $i}' | \
awk '{print $1}')

CPU_USAGE=$(echo "100 - $CPU_IDLE" | bc -l | \
awk '{printf "%.1f", $1}')

echo "CPU Usage: ${CPU_USAGE}%"


# =================================
# MEMORY USAGE
# =================================

MEMORY_USAGE=$(free | awk '/Mem:/ {
    printf "%.1f", ($3/$2)*100
}')

echo "Memory Usage: ${MEMORY_USAGE}%"


# =================================
# DISK USAGE
# =================================

DISK_USAGE=$(df / | awk 'NR==2 {
    gsub("%","")
    print $5
}')

echo "Disk Usage: ${DISK_USAGE}%"


# =================================
# NETWORK STATUS
# =================================

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


# =================================
# SYSTEM HEALTH STATUS
# =================================

if (( $(echo "$CPU_USAGE >= $CPU_CRITICAL" | bc -l) )) || \
   (( $(echo "$MEMORY_USAGE >= $MEMORY_CRITICAL" | bc -l) )) || \
   (( $(echo "$DISK_USAGE >= $DISK_CRITICAL" | bc -l) )) || \
   [ "$NETWORK_STATUS" = "DISCONNECTED" ]; then

    SYSTEM_STATUS="CRITICAL"

elif (( $(echo "$CPU_USAGE >= $CPU_WARNING" | bc -l) )) || \
     (( $(echo "$MEMORY_USAGE >= $MEMORY_WARNING" | bc -l) )) || \
     (( $(echo "$DISK_USAGE >= $DISK_WARNING" | bc -l) )); then

    SYSTEM_STATUS="WARNING"

else

    SYSTEM_STATUS="HEALTHY"

fi

echo "System Status: $SYSTEM_STATUS"


# =================================
# HEALTH MESSAGE
# =================================

if [ "$SYSTEM_STATUS" = "HEALTHY" ]; then

    echo "✅ Server is healthy."

elif [ "$SYSTEM_STATUS" = "WARNING" ]; then

    echo "⚠️ Server requires attention."

    echo "$(date) | WARNING | CPU=${CPU_USAGE}% | MEMORY=${MEMORY_USAGE}% | DISK=${DISK_USAGE}%" \
    >> "$PROJECT_DIR/logs/alerts.log"

else

    echo "🚨 CRITICAL: Server requires immediate attention."

    echo "$(date) | CRITICAL | CPU=${CPU_USAGE}% | MEMORY=${MEMORY_USAGE}% | DISK=${DISK_USAGE}% | NETWORK=$NETWORK_STATUS" \
    >> "$PROJECT_DIR/logs/alerts.log"

fi


# =================================
# TOP 5 CPU PROCESSES
# =================================

echo ""
echo "Top 5 CPU-consuming processes:"

ps aux --sort=-%cpu | head -n 6


# =================================
# SAVE TO LOG
# =================================

{
    echo "================================="
    echo "Linux Server Health Check"
    echo "================================="
    echo "Hostname: $(hostname)"
    echo "Date: $(date)"
    echo "CPU Usage: ${CPU_USAGE}%"
    echo "Memory Usage: ${MEMORY_USAGE}%"
    echo "Disk Usage: ${DISK_USAGE}%"
    echo "Network Status: $NETWORK_STATUS"
    echo "Network Latency: ${NETWORK_LATENCY} ms"
    echo "System Status: $SYSTEM_STATUS"
    echo "================================="
} >> "$LOG_FILE"
