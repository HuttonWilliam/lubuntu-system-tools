#!/bin/bash
# GFAF System Tools: Auto-Maintainer v1.0
# Designed for Lubuntu (LXQt) performance.

# 1. Start Logging (Keeping a Professional Record)
LOG_FILE="/var/log/gfaf_maintenance.log"
echo "--- Starting Maintenance: $(date) ---" | sudo tee -a $LOG_FILE

# 2. System Update (The "Governance" of Software)
echo "[1/4] Checking for software updates..."
sudo apt update && sudo apt dist-upgrade -y | sudo tee -a $LOG_FILE

# 3. Aggressive Cleanup (The "Health & Safety" for your SSD)
echo "[2/4] Removing orphaned packages and clearing cache..."
sudo apt autoremove -y
sudo apt autoclean
# Clears the thumbnail cache (huge space saver on Lubuntu)
rm -rf ~/.cache/thumbnails/* 

# 4. Error Check
if [ $? -eq 0 ]; then
    echo "[3/4] Maintenance Successful." | sudo tee -a $LOG_FILE
else
    echo "[3/4] WARNING: Issues detected during update." | sudo tee -a $LOG_FILE
fi

# 5. Final Telemetry
echo "[4/4] Current Disk Usage:"
df -h | grep '^/dev/'
echo "--- Maintenance Complete ---" | sudo tee -a $LOG_FILE
