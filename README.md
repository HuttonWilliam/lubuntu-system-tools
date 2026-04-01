# Lubuntu System Tools 🛠️

This repository contains custom Bash scripts I wrote to manage my Lubuntu workstation.

## 📂 Project Structure

* **backups/**: Tools to keep your code safe.
* **scripts/**: General system monitoring and maintenance.
* **setup/**: Automation for dev tools (ADB/Fastboot).

---

## 📜 Available Scripts

### 🕵️ System Access Logger
**Location:** `scripts/logger.sh`

This script records a timestamp, the current user, and system uptime into a text file.

**How to use:**
```bash
cd scripts
chmod +x logger.sh
./logger.sh
cat ~/Documents/access_report.txt
```

### 📊 System Information
**Location:** `scripts/sys-info.sh`

Displays general system information including CPU, memory, and disk usage.

**How to use:**
```bash
chmod +x sys-info.sh
./sys-info.sh
```

### 🔄 System Update
**Location:** `scripts/update-system.sh`

Automate system package updates.

**How to use:**
```bash
chmod +x update-system.sh
./update-system.sh
```

### 🧹 Disk Cleanup Utility
**Location:** `scripts/disk-cleanup.sh`

Remove temporary files, cache, logs, and reclaim disk space.

**Features:**
- Clean temporary files (/tmp, /var/tmp)
- Remove package manager cache (apt, snap)
- Delete old log files (>30 days)
- Clear thumbnail cache
- Empty trash bin
- Dry-run mode to preview changes

**How to use:**
```bash
chmod +x disk-cleanup.sh
./disk-cleanup.sh              # Run cleanup
./disk-cleanup.sh --dry-run    # Preview changes first
./disk-cleanup.sh --help       # Show help
```

### 💾 Backup Manager
**Location:** `scripts/backup-manager.sh`

Automate backup and restore of important files and configurations.

**Features:**
- Create timestamped backups
- Restore from any backup
- List all available backups
- Auto-cleanup old backups (>30 days)
- Backs up configs, documents, and settings

**How to use:**
```bash
chmod +x backup-manager.sh
./backup-manager.sh create --name "before-update"
./backup-manager.sh list
./backup-manager.sh restore --backup-id 20260401-110000
./backup-manager.sh clean
./backup-manager.sh help       # Show help
```

### 📈 Disk Usage Analyzer
**Location:** `scripts/disk-usage.sh`

Analyze disk space and find large files taking up storage.

**Features:**
- Filesystem overview
- Top 10 largest directories
- Find files larger than specified size
- File type analysis
- Home directory summary

**How to use:**
```bash
chmod +x disk-usage.sh
./disk-usage.sh                # Default analysis
./disk-usage.sh --size 1G      # Find files > 1GB
./disk-usage.sh --size 500M    # Find files > 500MB
./disk-usage.sh --help         # Show help
```

### ⚙️ Service Manager
**Location:** `scripts/service-manager.sh`

Manage systemd services, enable/disable services, and control startup.

**Features:**
- List all services with status
- Show active/inactive/failed services
- Start, stop, restart services
- Enable/disable services at boot
- Check individual service status

**How to use:**
```bash
chmod +x service-manager.sh
./service-manager.sh list
./service-manager.sh status ssh
sudo ./service-manager.sh start networking
sudo ./service-manager.sh enable ssh
sudo ./service-manager.sh disable cups
./service-manager.sh help      # Show help
```

---

## 🚀 Quick Start

1. Clone this repository:
```bash
git clone https://github.com/HuttonWilliam/lubuntu-system-tools.git
cd lubuntu-system-tools
```

2. Make all scripts executable:
```bash
chmod +x scripts/*.sh
```

3. Use any script:
```bash
./scripts/disk-cleanup.sh --help
./scripts/backup-manager.sh create
./scripts/disk-usage.sh
```

---
# Lubuntu System Tools
By William Hutton

A collection of lightweight Bash scripts designed to optimize Lubuntu 24.04 for high-performance and older hardware.

## Available Tools:
* **disk-cleanup.sh**: Removes temporary files and clears APT caches to save space.
* **backup-manager.sh**: Automates the backup of critical data.
* **disk-usage.sh**: Provides a detailed analysis of storage consumption.
* **service-manager.sh**: Manages startup services to minimize RAM usage.
* **update-system.sh**: Streamlines the `sudo apt` update and upgrade process.
* **sys-info.sh**: Quick diagnostic of system health and hardware stats.

## License:
This project is released under the MIT License.
## 💡 Tips

- Use `--help` or `help` flags on any script for detailed information
- Some scripts require `sudo` (service-manager, disk-cleanup)
- Try `--dry-run` before making permanent changes
- Regularly backup important data using `backup-manager.sh`
- Schedule scripts with cron for automated maintenance

---

## Technical Notes

[Lubuntu Official Site](https://lubuntu.me)

[Ubuntu Discourse](https://discourse.ubuntu.com)

Tested on: Lubuntu 24.04 LTS

---
