#!/bin/bash

# Backup manager script

# Define variables
BACKUP_DIR="/path/to/backup"
BACKUP_FILE="$BACKUP_DIR/backup-$(date +'%Y-%m-%d').tar.gz"

# Create backup
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_FILE" /path/to/data

# Inform the user
echo "Backup created at $BACKUP_FILE"