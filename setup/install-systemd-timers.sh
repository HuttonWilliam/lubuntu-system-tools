#!/bin/bash

# Lubuntu System Tools - Systemd Timer Installer
# Creates systemd service and timer files for each script
# Usage: ./install-systemd-timers.sh [--status] [--remove] [--help]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPTS_DIR="$REPO_DIR/scripts"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
LOG_DIR="/var/log/lubuntu-tools"
UNIT_PREFIX="lubuntu"

# ──────────────────────────────────────────────
# Helper print functions
# ──────────────────────────────────────────────
print_status()  { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error()   { echo -e "${RED}[✗]${NC} $1"; }
print_info()    { echo -e "${BLUE}[i]${NC} $1"; }

# ──────────────────────────────────────────────
# Help text
# ──────────────────────────────────────────────
show_help() {
    cat << EOF

${CYAN}Lubuntu System Tools - Systemd Timer Installer${NC}

USAGE:
    ./install-systemd-timers.sh [OPTIONS]

OPTIONS:
    (none)     Interactive setup - create and enable timers
    --status   Show status of all lubuntu systemd timers
    --remove   Remove all lubuntu systemd timer and service files
    --help     Show this help message

EXAMPLES:
    ./setup/install-systemd-timers.sh            # Interactive setup
    ./setup/install-systemd-timers.sh --status   # Show timer status
    ./setup/install-systemd-timers.sh --remove   # Remove all timers

TIMER FILES LOCATION:
    $SYSTEMD_USER_DIR/

LOG FILES:
    $LOG_DIR/

NOTES:
    - Scripts that require sudo are wrapped via a sudo exec command.
    - User systemd timers run only when the user is logged in unless
      loginctl enable-linger is set.
    - Run 'loginctl enable-linger \$USER' to allow timers to run at boot.

EOF
}

# ──────────────────────────────────────────────
# Show status of all lubuntu timers
# ──────────────────────────────────────────────
show_status() {
    echo -e "\n${CYAN}Lubuntu systemd timer status:${NC}\n"
    local found=false
    for timer_file in "$SYSTEMD_USER_DIR/${UNIT_PREFIX}"-*.timer; do
        [ -f "$timer_file" ] || continue
        found=true
        local unit
        unit=$(basename "$timer_file")
        echo -e "${YELLOW}$unit${NC}"
        systemctl --user status "$unit" --no-pager 2>/dev/null | head -n 8 || true
        echo
    done
    if [ "$found" = false ]; then
        print_info "No lubuntu systemd timers found."
    fi
}

# ──────────────────────────────────────────────
# Remove all lubuntu timer and service units
# ──────────────────────────────────────────────
remove_timers() {
    echo -e "\n${YELLOW}Removing all lubuntu systemd timers and services...${NC}"
    local found=false

    for timer_file in "$SYSTEMD_USER_DIR/${UNIT_PREFIX}"-*.timer; do
        [ -f "$timer_file" ] || continue
        found=true
        local unit
        unit=$(basename "$timer_file")
        systemctl --user stop "$unit" 2>/dev/null || true
        systemctl --user disable "$unit" 2>/dev/null || true
        rm -f "$timer_file"
        print_status "Removed timer: $unit"
    done

    for service_file in "$SYSTEMD_USER_DIR/${UNIT_PREFIX}"-*.service; do
        [ -f "$service_file" ] || continue
        found=true
        local unit
        unit=$(basename "$service_file")
        rm -f "$service_file"
        print_status "Removed service: $unit"
    done

    if [ "$found" = true ]; then
        systemctl --user daemon-reload
        print_status "Systemd daemon reloaded."
    else
        print_info "No lubuntu systemd units found to remove."
    fi
    echo
}

# ──────────────────────────────────────────────
# Prompt user to pick an OnCalendar value
# ──────────────────────────────────────────────
pick_calendar() {
    local script_name="$1"
    echo -e "\n${CYAN}Choose a schedule for ${YELLOW}$script_name${CYAN}:${NC}"
    echo "  1) Hourly"
    echo "  2) Daily (2 AM)"
    echo "  3) Daily (midnight)"
    echo "  4) Weekly (Sunday 3 AM)"
    echo "  5) Every 6 hours"
    echo "  6) Every 30 minutes"
    echo "  7) Custom OnCalendar expression"
    echo -n "  Enter choice [1-7]: "
    read -r cal_choice

    case "$cal_choice" in
        1) CALENDAR="hourly" ;;
        2) CALENDAR="*-*-* 02:00:00" ;;
        3) CALENDAR="daily" ;;
        4) CALENDAR="Sun *-*-* 03:00:00" ;;
        5) CALENDAR="*-*-* 00/6:00:00" ;;
        6) CALENDAR="*-*-* *:00/30:00" ;;
        7)
            echo -n "  Enter OnCalendar value (e.g. 'daily' or '*-*-* 02:00:00'): "
            read -r CALENDAR
            ;;
        *)
            print_warning "Invalid choice, using default: daily at 2 AM"
            CALENDAR="*-*-* 02:00:00"
            ;;
    esac
}

# ──────────────────────────────────────────────
# Create a service + timer unit pair
# ──────────────────────────────────────────────
create_unit_pair() {
    local script_name="$1"    # e.g. disk-cleanup.sh
    local description="$2"
    local calendar="$3"
    local needs_sudo="$4"     # true/false
    local script_args="$5"    # optional extra args

    local base="${script_name%.sh}"
    local unit_name="${UNIT_PREFIX}-${base}"
    local script_path="$SCRIPTS_DIR/$script_name"
    local log_file="$LOG_DIR/${base}.log"

    # Build ExecStart line
    local exec_line
    if [ "$needs_sudo" = true ]; then
        exec_line="ExecStart=/usr/bin/sudo $script_path $script_args"
    else
        exec_line="ExecStart=$script_path $script_args"
    fi

    # Write .service file
    cat > "$SYSTEMD_USER_DIR/${unit_name}.service" << EOF
[Unit]
Description=Lubuntu $description
After=network.target

[Service]
Type=oneshot
$exec_line
StandardOutput=append:$log_file
StandardError=append:$log_file

[Install]
WantedBy=default.target
EOF

    # Write .timer file
    cat > "$SYSTEMD_USER_DIR/${unit_name}.timer" << EOF
[Unit]
Description=Timer for Lubuntu $description

[Timer]
OnCalendar=$calendar
Persistent=true

[Install]
WantedBy=timers.target
EOF

    print_status "Created: ${unit_name}.service and ${unit_name}.timer"
}

# ──────────────────────────────────────────────
# Enable and start a timer
# ──────────────────────────────────────────────
enable_timer() {
    local unit_name="$1"
    systemctl --user daemon-reload
    systemctl --user enable "${unit_name}.timer" 2>/dev/null && \
        systemctl --user start "${unit_name}.timer" 2>/dev/null && \
        print_status "Enabled and started: ${unit_name}.timer" || \
        print_warning "Could not enable ${unit_name}.timer (user session may not be fully initialised)"
}

# ──────────────────────────────────────────────
# Interactive setup
# ──────────────────────────────────────────────
interactive_setup() {
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Lubuntu System Tools - Systemd Timer Installer  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}\n"

    # Ensure log directory exists
    if [ ! -d "$LOG_DIR" ]; then
        sudo mkdir -p "$LOG_DIR"
        sudo chmod 755 "$LOG_DIR"
        print_status "Created log directory: $LOG_DIR"
    fi

    # Ensure systemd user directory exists
    mkdir -p "$SYSTEMD_USER_DIR"
    print_status "Systemd user directory: $SYSTEMD_USER_DIR"

    declare -A SCRIPT_MAP
    SCRIPT_MAP=(
        [1]="backup-manager.sh"
        [2]="disk-cleanup.sh"
        [3]="update-system.sh"
        [4]="ram-manager.sh"
        [5]="sys-info.sh"
        [6]="auto-maintenance.sh"
    )

    declare -A DESC_MAP
    DESC_MAP=(
        [1]="Home Backup"
        [2]="Disk Cleanup"
        [3]="System Update"
        [4]="RAM Manager"
        [5]="System Info Logger"
        [6]="Auto Maintenance"
    )

    declare -A SUDO_MAP
    SUDO_MAP=(
        [1]=false
        [2]=true
        [3]=true
        [4]=false
        [5]=false
        [6]=true
    )

    echo -e "${CYAN}Available scripts to automate:${NC}"
    echo "  1) backup-manager.sh   - Automated home backup"
    echo "  2) disk-cleanup.sh     - Remove temp files and cache (requires sudo)"
    echo "  3) update-system.sh    - Update system packages (requires sudo)"
    echo "  4) ram-manager.sh      - Monitor and manage RAM"
    echo "  5) sys-info.sh         - Log system information"
    echo "  6) auto-maintenance.sh - Run all maintenance tasks (requires sudo)"
    echo "  7) All of the above"
    echo "  0) Cancel"
    echo -e "\nEnter numbers separated by spaces (e.g. '1 3 5'), or 7 for all:"
    echo -n "  Your choice: "
    read -r selection

    if [ "$selection" = "0" ]; then
        print_info "Setup cancelled."
        exit 0
    fi

    local selected_keys=()
    if [ "$selection" = "7" ]; then
        selected_keys=(1 2 3 4 5 6)
    else
        read -ra selected_keys <<< "$selection"
    fi

    local added=0
    for key in "${selected_keys[@]}"; do
        script_name="${SCRIPT_MAP[$key]}"
        description="${DESC_MAP[$key]}"
        needs_sudo="${SUDO_MAP[$key]}"

        if [ -z "$script_name" ]; then
            print_warning "Unknown selection: $key, skipping."
            continue
        fi

        if [ ! -f "$SCRIPTS_DIR/$script_name" ]; then
            print_warning "$script_name not found at $SCRIPTS_DIR/$script_name, skipping."
            continue
        fi

        pick_calendar "$script_name"
        create_unit_pair "$script_name" "$description" "$CALENDAR" "$needs_sudo" ""

        local base="${script_name%.sh}"
        local unit_name="${UNIT_PREFIX}-${base}"
        enable_timer "$unit_name"
        added=$((added + 1))
    done

    echo -e "\n${GREEN}╔══════════════════════════════════════════════════╗${NC}"
    printf "${GREEN}║  Setup Complete! Created %-2s timer(s).           ║${NC}\n" "$added"
    echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
    echo
    print_info "View timer status:   $0 --status"
    print_info "Remove all timers:   $0 --remove"
    print_info "View logs in:        $LOG_DIR/"
    print_info "Tip: Run 'loginctl enable-linger \$USER' to allow timers to"
    print_info "     run when you are not logged in."
    echo
}

# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────
main() {
    case "${1:-}" in
        --help)    show_help ;;
        --status)  show_status ;;
        --remove)  remove_timers ;;
        "")        interactive_setup ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
