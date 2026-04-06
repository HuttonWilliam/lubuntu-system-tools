# Automation Guide for Lubuntu System Tools 🤖

This guide explains how to schedule the scripts in this repository to run automatically, covering both **cron** and **systemd timers** approaches.

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Method 1 – Cron Jobs](#method-1--cron-jobs)
4. [Method 2 – Systemd Timers](#method-2--systemd-timers)
5. [Method 3 – Master Maintenance Script](#method-3--master-maintenance-script)
6. [Recommended Schedules](#recommended-schedules)
7. [Log Files](#log-files)
8. [Troubleshooting](#troubleshooting)
9. [Security Considerations](#security-considerations)
10. [Best Practices](#best-practices)

---

## Overview

| Method | Best For | Persistence | Complexity |
|--------|----------|-------------|------------|
| Cron | Simple time-based scheduling | Runs when user is logged in | Low |
| Systemd timers | Modern, event-driven scheduling | Can run at boot with linger | Medium |
| Master script | One-shot manual or scheduled runs | Any | Low |

---

## Quick Start

```bash
# Clone the repository
git clone https://github.com/HuttonWilliam/lubuntu-system-tools.git
cd lubuntu-system-tools

# Make all scripts executable
chmod +x scripts/*.sh setup/*.sh

# Option A: Set up cron jobs interactively
./setup/install-cron.sh

# Option B: Set up systemd timers interactively
./setup/install-systemd-timers.sh

# Option C: Run all maintenance manually right now
sudo ./scripts/auto-maintenance.sh
```

---

## Method 1 – Cron Jobs

Cron is the traditional Unix scheduler. It runs commands at fixed times based on a simple 5-field expression.

### Using the installer script

```bash
./setup/install-cron.sh            # Interactive setup
./setup/install-cron.sh --list     # List current lubuntu cron jobs
./setup/install-cron.sh --remove   # Remove all lubuntu cron jobs
./setup/install-cron.sh --help     # Show help
```

### Manual cron setup

```bash
crontab -e    # Open your crontab in the default editor
```

Add entries in this format:

```
minute hour day month weekday  command
```

#### Cron syntax reference

| Field | Range | Special characters |
|-------|-------|--------------------|
| minute | 0–59 | `*` `,` `-` `/` |
| hour | 0–23 | `*` `,` `-` `/` |
| day of month | 1–31 | `*` `,` `-` `/` |
| month | 1–12 | `*` `,` `-` `/` |
| day of week | 0–7 (0=Sunday) | `*` `,` `-` `/` |

Common patterns:

```
0 2 * * *      # Daily at 2 AM
0 3 * * 0      # Every Sunday at 3 AM
*/30 * * * *   # Every 30 minutes
0 */6 * * *    # Every 6 hours
@reboot        # Once at system boot
```

#### Example crontab entries

```bash
# Daily backup at 2 AM
0 2 * * *  /home/user/lubuntu-system-tools/scripts/backup-manager.sh >> /var/log/lubuntu-tools/backup.log 2>&1

# Weekly disk cleanup (Sunday 3 AM)
0 3 * * 0  sudo /home/user/lubuntu-system-tools/scripts/disk-cleanup.sh >> /var/log/lubuntu-tools/disk-cleanup.log 2>&1

# Daily system update at midnight
0 0 * * *  sudo /home/user/lubuntu-system-tools/scripts/update-system.sh >> /var/log/lubuntu-tools/update.log 2>&1

# Hourly system info snapshot
0 * * * *  /home/user/lubuntu-system-tools/scripts/sys-info.sh >> /var/log/lubuntu-tools/sys-info.log 2>&1
```

> **Tip:** Always use full absolute paths in cron entries.

---

## Method 2 – Systemd Timers

Systemd timers are the modern replacement for cron. They integrate with the systemd journal and support more flexible calendar expressions.

### Using the installer script

```bash
./setup/install-systemd-timers.sh            # Interactive setup
./setup/install-systemd-timers.sh --status   # Show timer status
./setup/install-systemd-timers.sh --remove   # Remove all timers
./setup/install-systemd-timers.sh --help     # Show help
```

Timer and service files are created in `~/.config/systemd/user/`.

### Manual systemd timer setup

#### 1. Create a service file

`~/.config/systemd/user/lubuntu-backup.service`:

```ini
[Unit]
Description=Lubuntu Home Backup
After=network.target

[Service]
Type=oneshot
ExecStart=/home/user/lubuntu-system-tools/scripts/backup-manager.sh
StandardOutput=append:/var/log/lubuntu-tools/backup.log
StandardError=append:/var/log/lubuntu-tools/backup.log

[Install]
WantedBy=default.target
```

#### 2. Create a timer file

`~/.config/systemd/user/lubuntu-backup.timer`:

```ini
[Unit]
Description=Timer for Lubuntu Home Backup

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

#### 3. Enable and start the timer

```bash
systemctl --user daemon-reload
systemctl --user enable lubuntu-backup.timer
systemctl --user start lubuntu-backup.timer
```

#### 4. Check timer status

```bash
systemctl --user list-timers
systemctl --user status lubuntu-backup.timer
```

### Run timers at boot (without login)

```bash
loginctl enable-linger $USER
```

This allows user systemd timers to run even when you are not logged in.

### OnCalendar examples

```
hourly                   # Every hour on the hour
daily                    # Every day at midnight
weekly                   # Every Monday at midnight
*-*-* 02:00:00           # Every day at 2 AM
Sun *-*-* 03:00:00       # Every Sunday at 3 AM
*-*-* 00/6:00:00         # Every 6 hours
*-*-* *:00/30:00         # Every 30 minutes
```

---

## Method 3 – Master Maintenance Script

`scripts/auto-maintenance.sh` runs all tasks in sequence with a single command.

```bash
./scripts/auto-maintenance.sh              # Run all maintenance tasks
./scripts/auto-maintenance.sh --dry-run    # Preview what would happen
./scripts/auto-maintenance.sh --backup     # Run only backup
./scripts/auto-maintenance.sh --cleanup    # Run only cleanup
./scripts/auto-maintenance.sh --update     # Run only system update
./scripts/auto-maintenance.sh --ram        # Run only RAM management
./scripts/auto-maintenance.sh --help       # Show help
```

Then schedule the master script via cron or a systemd timer:

```bash
# Daily full maintenance at 3 AM via cron
0 3 * * * sudo /home/user/lubuntu-system-tools/scripts/auto-maintenance.sh
```

---

## Recommended Schedules

| Script | Recommended Frequency | Notes |
|--------|-----------------------|-------|
| `backup-manager.sh` | Daily at 2 AM | Protects recent work |
| `disk-cleanup.sh` | Weekly (Sunday 3 AM) | Avoid too frequent |
| `update-system.sh` | Daily at midnight | Keep system secure |
| `sys-info.sh` | Hourly | Useful for monitoring |
| `ram-manager.sh` | Every 6 hours | Monitor memory trends |
| `auto-maintenance.sh` | Weekly (Sunday 4 AM) | Full maintenance run |

---

## Log Files

All scripts write to `/var/log/lubuntu-tools/`:

```
/var/log/lubuntu-tools/
├── auto-maintenance-<timestamp>.log   # Master maintenance log
├── backup.log                         # Backup task output
├── disk-cleanup.log                   # Cleanup task output
├── update-system.log                  # Update task output
├── ram-manager.log                    # RAM task output
└── sys-info.log                       # System info log
```

### Viewing logs

```bash
# View latest maintenance run
ls -t /var/log/lubuntu-tools/auto-maintenance-*.log | head -1 | xargs cat

# Follow a log in real time
tail -f /var/log/lubuntu-tools/backup.log

# View systemd timer logs
journalctl --user -u lubuntu-backup.service
```

---

## Troubleshooting

### Cron job not running

1. Check the cron service is running:
   ```bash
   systemctl status cron
   ```
2. Verify your crontab:
   ```bash
   crontab -l
   ```
3. Check the system mail for cron error output:
   ```bash
   cat /var/mail/$USER
   ```
4. Ensure the script has execute permission and uses absolute paths.

### Systemd timer not running

1. Check if the timer is enabled and active:
   ```bash
   systemctl --user list-timers
   ```
2. Check the service logs:
   ```bash
   journalctl --user -u lubuntu-backup.service --since today
   ```
3. Reload daemon after editing unit files:
   ```bash
   systemctl --user daemon-reload
   ```

### Permission errors

Scripts that need elevated privileges should use `sudo`. For automated runs, add a sudoers entry to avoid password prompts:

```bash
sudo visudo
# Add (replace <your-username> with your actual username):
<your-username> ALL=(ALL) NOPASSWD: /home/<your-username>/lubuntu-system-tools/scripts/disk-cleanup.sh
```

---

## Security Considerations

- **Limit sudo scope**: Only grant `NOPASSWD` for specific scripts, not blanket access.
- **Validate input**: Scripts should not accept untrusted input when running automatically.
- **Review scripts before scheduling**: Understand what each script does before automating it.
- **Protect log files**: Log files may contain system information. Ensure `/var/log/lubuntu-tools/` has appropriate permissions.
- **Use absolute paths**: Always use absolute paths in cron entries to avoid PATH-related issues.
- **Audit crontab**: Regularly review `crontab -l` to ensure no unauthorised entries exist.

---

## Best Practices

1. **Test before scheduling**: Run each script manually first to ensure it works correctly.
2. **Use `--dry-run`**: Most scripts support `--dry-run` to preview changes safely.
3. **Back up crontab**: The installer automatically backs up your crontab before changes.
4. **Monitor logs**: Check `/var/log/lubuntu-tools/` periodically for errors.
5. **Avoid overlapping schedules**: Stagger tasks to prevent simultaneous resource usage.
6. **Keep scripts updated**: Pull the latest changes from the repository regularly.
7. **Prefer systemd timers**: For modern Lubuntu, systemd timers provide better logging and reliability.

---

*Lubuntu System Tools — by William Hutton*
