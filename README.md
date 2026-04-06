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

### 🔋 Battery Health Monitor
**Location:** `scripts/battery-monitor.sh`

Monitor battery health, charge status, and power usage on laptops.

**Features:**
- Display current battery percentage and status (charging/discharging/full)
- Show battery health (capacity vs design capacity) with degradation warnings
- Estimate time to full charge or time remaining
- Monitor charge cycles, manufacturer info, and battery technology
- Power consumption analysis (current draw / watt usage)
- Display battery temperature (requires lm-sensors)
- Option to enable/disable power-saving mode (via TLP or cpufreq)
- Colorized output for easy reading
- Real-time monitoring mode

**How to use:**
```bash
chmod +x battery-monitor.sh
./battery-monitor.sh                 # Show current battery status
./battery-monitor.sh --health        # Show detailed health info
./battery-monitor.sh --powersave on  # Enable power-saving mode
./battery-monitor.sh --watch         # Monitor battery in real-time
./battery-monitor.sh --help          # Show help
```

### ⚡ System Performance Optimizer
**Location:** `scripts/performance-tuner.sh`

Optimize system performance and resource usage on Lubuntu.

**Features:**
- Display current system performance metrics (CPU, memory, I/O, load)
- Optimize CPU governor (schedutil/ondemand for balanced performance)
- Manage swappiness settings (lower = less swap usage)
- Clear memory caches safely
- Optimize I/O scheduler per block device
- Audit and suggest disabling unnecessary background services
- Generate detailed performance report saved to /tmp
- Restore default settings option
- Dry-run mode to preview changes safely

**How to use:**
```bash
chmod +x performance-tuner.sh
./performance-tuner.sh                   # Show current performance stats
./performance-tuner.sh --optimize        # Run optimization
./performance-tuner.sh --report          # Generate performance report
./performance-tuner.sh --cpu powersave   # Change CPU governor
./performance-tuner.sh --swap 10         # Set swappiness to 10
./performance-tuner.sh --reset           # Restore default settings
./performance-tuner.sh --dry-run --optimize  # Preview optimizations
./performance-tuner.sh --help            # Show help
```

---

## 🤖 Automation Setup

Automate your system maintenance with the included setup scripts.

### Option 1 – Cron Jobs (traditional)

```bash
chmod +x setup/install-cron.sh
./setup/install-cron.sh            # Interactive setup
./setup/install-cron.sh --list     # List current cron jobs
./setup/install-cron.sh --remove   # Remove all lubuntu cron jobs
./setup/install-cron.sh --help     # Show help
```

### Option 2 – Systemd Timers (modern)

```bash
chmod +x setup/install-systemd-timers.sh
./setup/install-systemd-timers.sh            # Interactive setup
./setup/install-systemd-timers.sh --status   # Show timer status
./setup/install-systemd-timers.sh --remove   # Remove all timers
```

### Option 3 – Master Maintenance Script

Run all critical tasks in one command:

```bash
chmod +x scripts/auto-maintenance.sh
./scripts/auto-maintenance.sh              # Run all maintenance tasks
./scripts/auto-maintenance.sh --dry-run    # Preview what will happen
./scripts/auto-maintenance.sh --backup     # Run only backup
./scripts/auto-maintenance.sh --cleanup    # Run only cleanup
./scripts/auto-maintenance.sh --update     # Run only system update
./scripts/auto-maintenance.sh --help       # Show help
```

### Recommended Schedules

| Script | Frequency | Method |
|--------|-----------|--------|
| `backup-manager.sh` | Daily at 2 AM | Cron or systemd timer |
| `disk-cleanup.sh` | Weekly (Sunday 3 AM) | Cron or systemd timer |
| `update-system.sh` | Daily at midnight | Cron or systemd timer |
| `sys-info.sh` | Hourly | Cron or systemd timer |
| `auto-maintenance.sh` | Weekly | Cron or systemd timer |

Log files are written to `/var/log/lubuntu-tools/`.

See [AUTOMATION_GUIDE.md](AUTOMATION_GUIDE.md) for the full guide including cron syntax, systemd timer concepts, log monitoring, and troubleshooting.

---

## 🚀 Quick Start

1. Clone this repository:
```bash
git clone https://github.com/HuttonWilliam/lubuntu-system-tools.git
cd lubuntu-system-tools
```

2. Make all scripts executable:
```bash
chmod +x scripts/*.sh setup/*.sh
```

3. Use any script:
```bash
./scripts/disk-cleanup.sh --help
./scripts/backup-manager.sh create
./scripts/disk-usage.sh
```

4. Set up automation:
```bash
./setup/install-cron.sh       # Set up cron jobs
# or
./setup/install-systemd-timers.sh  # Set up systemd timers
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
* **battery-monitor.sh**: Monitors battery health, charge status, and power usage on laptops.
* **performance-tuner.sh**: Optimizes system performance (CPU governor, swappiness, I/O scheduler).

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
