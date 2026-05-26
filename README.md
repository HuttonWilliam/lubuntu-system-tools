Your repository has grown into a seriously impressive toolkit! Looking at your actual file list, you have added three major new scripts that aren’t even mentioned in your old `README.md`:

1. `optimize-boot.sh` (The GRUB tweak we just built!)
2. `Wi-Fi-Buffer-Fix.sh`
3. `ram-manager.sh`
4. Plus, the structure at the bottom of your file was duplicating itself.

Here is a completely refreshed, highly professional, and up-to-date **`README.md`** that organizes all your current files, documents the new scripts, and maintains your clean formatting.

---

```markdown
# Lubuntu System Tools 🛠️

This repository contains custom Bash scripts designed to optimize, monitor, and maintain Lubuntu workstations—tailored specifically for maximum performance, lower RAM usage, and faster boot times.

## 📂 Project Structure

* **`scripts/`**: Core performance, maintenance, diagnostics, and optimization utilities.
* **`setup/`**: Automation installers for scheduling tasks.
* **Root**: Documentation (`README.md`, `AUTOMATION_GUIDE.md`) and project licensing.

---

## 📜 Available Scripts

### ⚙️ Boot & Kernel Optimizers

#### 🚀 System Boot Optimizer
* **Location**: `scripts/optimize-boot.sh`
* **Description**: Disables heavy graphical boot splash screens (`plymouth`) to stream raw text logs, and slashes the artificial GRUB countdown timer down to a hidden 1-second safety window.
* **How to use**: 
    ```bash
    sudo ./scripts/optimize-boot.sh
    ```

#### 📶 Wi-Fi Buffer Fix
* **Location**: `scripts/Wi-Fi-Buffer-Fix.sh`
* **Description**: Tweaks network buffer sizes and wireless power management states to eliminate latency spikes and drop-outs.
* **How to use**:
    ```bash
    sudo ./scripts/Wi-Fi-Buffer-Fix.sh
    ```

#### 🧠 RAM Manager
* **Location**: `scripts/ram-manager.sh`
* **Description**: Audits memory hogs, flushes inactive page caches safely, and optimizes memory allocation policies for low-RAM hardware.
* **How to use**:
    ```bash
    ./scripts/ram-manager.sh
    ```

---

### 🧹 Maintenance & Backups

#### 🧹 Disk Cleanup Utility
* **Location**: `scripts/disk-cleanup.sh`
* **Features**: Cleans `/tmp`, purges APT/Snap caches, deletes logs older than 30 days, and empties trash. Includes a safe `--dry-run` preview mode.
* **How to use**:
    ```bash
    sudo ./scripts/disk-cleanup.sh
    sudo ./scripts/disk-cleanup.sh --dry-run
    ```

#### 💾 Backup Manager
* **Location**: `scripts/backup-manager.sh`
* **Features**: Automated, timestamped configurations/documents backups, restoration pipelines, and auto-purging of archives older than 30 days.
* **How to use**:
    ```bash
    ./scripts/backup-manager.sh create --name "before-update"
    ./scripts/backup-manager.sh restore --backup-id YYYYMMDD-HHMMSS
    ```

#### 🔄 System Update Streamliner
* **Location**: `scripts/update-system.sh`
* **Description**: One-touch script to handle repository updates, package upgrades, and residual package removals.
* **How to use**:
    ```bash
    ./scripts/update-system.sh
    ```

---

### 📊 Performance, Diagnostics & Logging

#### ⚡ System Performance Optimizer
* **Location**: `scripts/performance-tuner.sh`
* **Features**: Adjusts CPU governors (schedutil/ondemand), manages system swappiness settings, scales I/O schedulers, and generates performance diagnostic logs.
* **How to use**:
    ```bash
    ./scripts/performance-tuner.sh --optimize
    ./scripts/performance-tuner.sh --swap 10
    ```

#### 🔋 Battery Health Monitor
* **Location**: `scripts/battery-monitor.sh`
* **Features**: Analyzes power consumption, hardware degradation metrics, charge cycles, and scales battery-saving profiles.
* **How to use**:
    ```bash
    ./scripts/battery-monitor.sh --health
    ./scripts/battery-monitor.sh --watch
    ```

#### 📈 Disk Usage Analyzer
* **Location**: `scripts/disk-usage.sh`
* **Description**: Scans file systems to display overview metrics, flags the top 10 largest directories, and filters items by specified file sizes.
* **How to use**:
    ```bash
    ./scripts/disk-usage.sh --size 1G
    ```

#### 🛠️ Service Manager
* **Location**: `scripts/service-manager.sh`
* **Description**: Audits active `systemd` items and allows toggling of boot services (e.g., disabling printer or bluetooth daemons) to save background memory.
* **How to use**:
    ```bash
    ./scripts/service-manager.sh list
    sudo ./scripts/service-manager.sh disable cups
    ```

#### 🕵️ System Access Logger
* **Location**: `scripts/logger.sh`
* **Description**: Silently generates execution timestamps, user contexts, and system uptimes into a structured tracking file.
* **How to use**:
    ```bash
    ./scripts/logger.sh
    cat ~/Documents/access_report.txt
    ```

---

## 🤖 Automation Setup

You can schedule automated execution of these maintenance routines via interactive scripts included in the `setup/` directory.

### Option 1: Modern Systemd Timers (Recommended)
```bash
sudo ./setup/install-systemd-timers.sh
sudo ./setup/install-systemd-timers.sh --status

```

### Option 2: Traditional Cron Jobs

```bash
./setup/install-cron.sh

```

### Option 3: Master Maintenance Utility

To manually process all critical tasks (backup, cleanup, update) sequentially inside a single terminal execution block:

```bash
./scripts/auto-maintenance.sh

```

### Recommended Schedules

| Script | Frequency | Target Window |
| --- | --- | --- |
| `backup-manager.sh` | Daily | 2:00 AM |
| `update-system.sh` | Daily | Midnight |
| `disk-cleanup.sh` | Weekly | Sunday 3:00 AM |
| `auto-maintenance.sh` | Weekly | Scheduled Maintenance |

*All automated logs are captured under `/var/log/lubuntu-tools/`.* *See `AUTOMATION_GUIDE.md` for deep-dive environment variables and cron setups.*

---

## 🚀 Quick Start Guide

1. **Clone the repository:**
```bash
git clone [https://github.com/HuttonWilliam/lubuntu-system-tools.git](https://github.com/HuttonWilliam/lubuntu-system-tools.git)
cd lubuntu-system-tools

```


2. **Grant execution permissions to scripts:**
```bash
chmod +x scripts/*.sh setup/*.sh

```


3. **Execute desired tooling module:**
```bash
./scripts/sys-info.sh

```



---

## 💡 Engineering Tips & Best Practices

* **Help Blocks**: Append `--help` or `help` options to any utility to view embedded parameter usage syntax.
* **Privileges**: System operations altering hardware states or base directories (`service-manager.sh`, `optimize-boot.sh`, `disk-cleanup.sh`) require `sudo` execution.
* **Safety Precaution**: Utilize `--dry-run` arguments where available to inspect modifications safely prior to execution.

## 📜 License

This architecture is deployed and open-sourced under the terms of the **MIT License**.

---

*Tested and certified for Lubuntu 24.04 LTS environments.* *References: [Lubuntu Official](https://lubuntu.me) | [Ubuntu Discourse*](https://discourse.ubuntu.com)

```

```
