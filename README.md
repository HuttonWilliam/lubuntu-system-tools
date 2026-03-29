# Lubuntu System Tools 🛠️

This repository contains custom Bash scripts I wrote to manage my Lubuntu workstation and old hardware like the Nexus 7.

## 📂 Project Structure

* **backups/**: Tools to keep your code safe.
* **scripts/**: General system monitoring.
* **setup/**: Automation for dev tools (ADB/Fastboot).

---

## 🕵️ System Access Logger
**Location:** `scripts/logger.sh`

This script records a timestamp, the current user, and system uptime into a text file.

**How to use:**
1. Enter the folder: `cd scripts`
2. Give permission: `chmod +x logger.sh`
3. Run it: `./logger.sh`
4. View the log: `cat ~/Documents/access_report.txt`

---

## 📱 Nexus 7 Setup Tool
**Location:** `setup/setup_dev_tools.sh`

Automates the installation of ADB and Fastboot for working with Android devices on Lubuntu.

**How to use:**
1. Enter the folder: `cd setup`
2. Run it: `bash setup_dev_tools.sh`
