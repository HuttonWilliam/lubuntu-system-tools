#!/bin/bash
# Title: Full Lubuntu Updater
echo "🔄 Checking for updates..."
sudo apt update && sudo apt upgrade -y
echo "🧹 Cleaning up old files..."
sudo apt autoremove -y
echo "✅ System is up to date!"
