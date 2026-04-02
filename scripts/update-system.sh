#!/bin/bash
set -e  # <--- FIXES ISSUE #1 (The Safety Switch)

# Title: Full Lubuntu Updater
echo "🔄 Checking for updates..."

# full-upgrade ensures every single component is actually updated
sudo apt update && sudo apt full-upgrade -y  # <--- FIXES ISSUE #3

echo "🧹 Cleaning up old files..."
sudo apt autoremove -y

echo "✅ System is up to date!"
