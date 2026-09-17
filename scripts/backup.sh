#!/bin/bash

# =================================
# Linux Server Monitor Backup
# =================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."

BACKUP_DIR="$PROJECT_DIR/backups"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

BACKUP_FILE="$BACKUP_DIR/server-monitor-$DATE.tar.gz"

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "Creating backup..."

tar -czf "$BACKUP_FILE" \
    "$PROJECT_DIR/scripts" \
    "$PROJECT_DIR/config" \
    "$PROJECT_DIR/logs" \
    "$PROJECT_DIR/reports"

if [ $? -eq 0 ]; then
    echo "Backup created successfully!"
    echo "Backup file: $BACKUP_FILE"
else
    echo "ERROR: Backup failed!"
    exit 1
fi

echo "================================="
