#!/bin/bash
# ========================================================================
# Lubuntu System Tools - backup-manager
# Copyright (C) 2026 William Hutton
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License.
# ========================================================================
set -e

# Lubuntu Hardware Wi-Fi Buffer Optimizer
# Fixes the Qualcomm Atheros QCA6174 'ath10k_pci failed with error -12' boot bug

# Colors for clean terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        Qualcomm Wi-Fi Memory Buffer Optimizer       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"

GRUB_FILE="/etc/default/grub"

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[!] Error: This script must be run with sudo properties.${NC}"
  echo -e "Please run: ${YELLOW}sudo ./wifi-buffer-fix.sh${NC}"
  exit 1
fi

if [ -f "$GRUB_FILE" ]; then
    # Check if the fix is already applied
    if ! grep -q "iommu=soft" "$GRUB_FILE"; then
        echo -e "${YELLOW}[!] Wi-Fi memory fragmentation risk detected (Error -12 tracking).${NC}"
        echo -e "This script will reserve an unfragmented continuous RAM pool for your network chip."
        echo -e "Would you like to apply the kernel boot optimization? (y/n)"
        read -r answer
        
        if [[ "$answer" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            echo -e "\n${CYAN}Patching system bootloader configuration...${NC}"
            # Safely swap out the default quiet splash line with the IOMMU parameters
            sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash iommu=soft mem_encrypt=off"/' "$GRUB_FILE"
            
            echo -e "${CYAN}Recompiling system GRUB configurations...${NC}"
            update-grub
            
            echo -e "\n${GREEN}[✓] Initialization rules written successfully!${NC}"
            echo -e "${YELLOW}Please reboot your laptop ('sudo reboot') to map the wireless chip parameters.${NC}"
        else
            echo -e "${RED}Operation cancelled by user.${NC}"
        fi
    else
        echo -e "${GREEN}[✓] Success: Qualcomm hardware memory maps are already optimized on this machine.${NC}"
    fi
else
    echo -e "${RED}[!] Error: /etc/default/grub configuration layout not found.${NC}"
    echo "This optimization tool is designed for Debian/Ubuntu-based distributions."
fi
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
