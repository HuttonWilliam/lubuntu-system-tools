#!/bin/bash

# Lubuntu Backup Manager
# A lightweight tool to compress and save your Documents

# Define variables
BACKUP_DIR="$HOME/Backups"
DATA_TO_BACKUP="$HOME/Documents" 
BACKUP_FILE="$BACKUP_DIR/backup-$(date +'%Y-%m-%d').tar.gz"

# Create backup folder if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Starting System Backup..."
echo "Target: $DATA_TO_BACKUP"

# Create the compressed backup
tar -czf "$BACKUP_FILE" "$DATA_TO_BACKUP"

# Inform the user
echo "-----------------------------------"
echo "Success! Backup created at: $BACKUP_FILE"
echo "Size: $(du -h "$BACKUP_FILE" | cut -f1)"
echo "-----------------------------------"
