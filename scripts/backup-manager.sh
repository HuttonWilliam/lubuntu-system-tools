#!/bin/bash
# Exit immediately if a command fails
set -e 

# Title: Lubuntu Home Backup Manager
# Developed to address feedback on backup scope and error handling

# Define variables
# SOURCE is your entire Home folder (Photos, Downloads, Desktop, etc.)
SOURCE_DIR="$HOME"
# DEST is where the backup goes
BACKUP_DIR="$HOME/Backups"

# Create the backup folder if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "-----------------------------------"
echo "🚀 Starting Full Home Backup..."
echo "Source: $SOURCE_DIR"
echo "Destination: $BACKUP_DIR"
echo "-----------------------------------"

# Run rsync
# -a: archive mode (keeps permissions and timestamps)
# -v: verbose (shows you what is happening)
# --delete: removes files from backup if you deleted them from Home
# --exclude: ignores the backup folder itself to avoid an infinite loop
rsync -av --delete --exclude='Backups/' --exclude='.cache/' "$SOURCE_DIR/" "$BACKUP_DIR/"

echo "-----------------------------------"
echo "✅ Success! Your $HOME folder is backed up."
echo "Backup Size: $(du -sh "$BACKUP_DIR" | cut -f1)"
echo "-----------------------------------"
