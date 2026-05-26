#!/bin/bash
# ========================================================================
# Lubuntu System Tools - Boot Optimizer
# Copyright (C) 2026 William Hutton
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License.
# ========================================================================
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
