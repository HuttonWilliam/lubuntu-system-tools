#!/bin/bash
# ========================================================================
# Lubuntu System Tools - Boot Optimizer
# Copyright (C) 2026 William Hutton
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License.
# ========================================================================
set -e  # <--- FIXES ISSUE #1 (The Safety Switch)

# Title: Full Lubuntu Updater
echo "🔄 Checking for updates..."

# full-upgrade ensures every single component is actually updated
sudo apt update && sudo apt full-upgrade -y  # <--- FIXES ISSUE #3

echo "🧹 Cleaning up old files..."
sudo apt autoremove -y

echo "✅ System is up to date!"
