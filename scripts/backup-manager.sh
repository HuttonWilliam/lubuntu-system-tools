#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e 

# Lubuntu Backup Manager
# Improved version addressing GitHub Issue #1 and #6

# Define variables - Now backing up the entire HOME folder
BACKUP_DIR="$HOME/Backups"
SOURCE_DATA="$HOME" 

# Create backup folder if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Starting System Backup..."
echo "Source: $SOURCE_DATA"
echo "Destination: $BACKUP_DIR"

# Using rsync to sync the Home folder
# -a: Archive mode (preserves permissions)
# -v: Verbose (shows progress)
# --delete: Removes files in backup that were deleted in Source
# --exclude: Don't backup trash or temporary cache files
rsync -av --delete \
  --exclude='.cache' \
  --exclude='.local/share/Trash' \
  --exclude='Backups' \
  "$SOURCE_DATA/" "$BACKUP_DIR/"

echo "-----------------------------------"
echo "Success! Backup synced to: $BACKUP_DIR"
echo "Total Backup Size: $(du -sh "$BACKUP_DIR" | cut -f1)"
echo "-----------------------------------"
