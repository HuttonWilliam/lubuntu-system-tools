#!/bin/bash
# ========================================================================
# Lubuntu System Tools - logger
# Copyright (C) 2026 William Hutton
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License.
# ========================================================================
# --- Lubuntu Access Log ---
# Created by: William Hutton
# This script records exactly when the computer was accessed.

LOGFILE="$HOME/Documents/access_report.txt"

echo "-----------------------------------" >> $LOGFILE
echo "Access Detected: $(date)" >> $LOGFILE
echo "User: $(whoami)" >> $LOGFILE
echo "Uptime: $(uptime -p)" >> $LOGFILE
echo "-----------------------------------" >> $LOGFILE

echo "✅ Entry recorded in Documents/access_report.txt"
