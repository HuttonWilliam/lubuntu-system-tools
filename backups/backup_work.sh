#!/bin/bash
# Backup all .sh files to a new folder
DEST="$HOME/Documents/Lubuntu_Backup_$(date +%Y-%m-%d)"
mkdir -p "$DEST"
cp ~/Documents/*.sh "$DEST" 2>/dev/null
echo "✅ Backup complete! Saved to $DEST"
