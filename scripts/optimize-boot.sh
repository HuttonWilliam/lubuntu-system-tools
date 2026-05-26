#!/bin/bash
# ========================================================================
# Lubuntu System Tools - Boot Optimizer
# Copyright (C) 2026 William Hutton
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License.
# ========================================================================

# Ensure the script is run with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo (e.g., sudo ./optimize-boot.sh)"
  exit 1
fi

echo "Starting Lubuntu boot optimization..."

# 1. Backup the original GRUB file just in case
cp /etc/default/grub /etc/default/grub.bak
echo "✔ Created a backup of your original GRUB config at /etc/default/grub.bak"

# 2. Overwrite the GRUB file with the optimized settings
cat << 'EOF' > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT_STYLE=hidden
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR='Ubuntu'
GRUB_CMDLINE_LINUX_DEFAULT="quiet iommu=soft mem_encrypt=off"
GRUB_CMDLINE_LINUX=""
EOF

echo "✔ Applied optimized GRUB settings (Timeout: 1s, Style: Hidden)."

# 3. Recompile GRUB so the system updates
echo "Updating GRUB hardware maps..."
update-grub

echo "🎉 Optimization complete! Your next boot will be significantly faster."
