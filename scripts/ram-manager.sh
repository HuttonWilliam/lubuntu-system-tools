#!/bin/bash

# Lubuntu RAM Manager
# Identifies memory hogs and clears system cache

# Colors for professional output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Lubuntu RAM Manager             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

# 1. Display Current RAM Usage
echo -e "${YELLOW}Current Memory Status:${NC}"
free -h

# 2. Show Top 5 Memory Hogs
# This looks at PID (Process ID), Name, % of Memory, and % of CPU
echo -e "\n${RED}Top 5 Processes by RAM Usage:${NC}"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6

# 3. Option to Clear System Cache
echo -e "\n${YELLOW}Would you like to clear the System Cache? (y/n)${NC}"
read -r answer

if [[ "$answer" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Clearing PageCache, Dentries, and Inodes..."
    # 'sync' flushes the file system buffers to disk first
    sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    echo -e "${GREEN}[✓] RAM Cache Cleared!${NC}"
    free -h
else
    echo "Skipping cache clear."
fi
