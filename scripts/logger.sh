#!/bin/bash

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
