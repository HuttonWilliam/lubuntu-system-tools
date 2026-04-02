#!/bin/bash
set -e

echo "--- 🖥️ LUBUNTU SYSTEM DASHBOARD ---"

echo "--- 💿 DISK & STORAGE TOPOLOGY ---"
# This shows all connected disks (Issue fix!)
lsblk -p -o NAME,SIZE,TYPE,MOUNTPOINT

echo ""
echo "--- 📊 MEMORY USAGE ---"
free -h

echo ""
echo "--- 📅 UPTIME ---"
uptime -p
