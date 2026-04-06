#!/bin/bash

# Lubuntu System Tools - Cron Job Installer
# Sets up automated cron jobs for all system tools
# Usage: ./install-cron.sh [--help] [--list] [--remove]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Detect script and repo directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPTS_DIR="$REPO_DIR/scripts"
LOG_DIR="/var/log/lubuntu-tools"
CRON_BACKUP_DIR="$HOME/.lubuntu-cron-backups"
CRON_TAG="# lubuntu-system-tools"

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

${CYAN}Lubuntu System Tools - Cron Job Installer${NC}

USAGE:
    ./install-cron.sh [OPTIONS]

OPTIONS:
    (none)     Interactive setup - choose which scripts to automate
    --list     List all currently installed lubuntu cron jobs
    --remove   Remove all lubuntu-system-tools cron jobs
    --help     Show this help message

EXAMPLES:
    ./setup/install-cron.sh            # Interactive setup
    ./setup/install-cron.sh --list     # List current cron jobs
    ./setup/install-cron.sh --remove   # Remove all lubuntu cron jobs

AVAILABLE SCRIPTS:
    backup-manager.sh   - Automated home backup
    disk-cleanup.sh     - Remove temp files and cache
    update-system.sh    - Update system packages
    ram-manager.sh      - Monitor and manage RAM
    sys-info.sh         - Log system information
    auto-maintenance.sh - Run all maintenance tasks

LOG FILES:
    Cron output is saved to: $LOG_DIR/
    Cron backups stored in:  $CRON_BACKUP_DIR/

EOF
}

# ──────────────────────────────────────────────
# List lubuntu cron jobs
# ──────────────────────────────────────────────
list_cron_jobs() {
    echo -e "\n${CYAN}Current lubuntu-system-tools cron jobs:${NC}\n"
    local jobs
    jobs=$(crontab -l 2>/dev/null | grep "$CRON_TAG")
    if [ -z "$jobs" ]; then
        print_info "No lubuntu-system-tools cron jobs found."
    else
        echo "$jobs"
    fi
    echo
}

# ──────────────────────────────────────────────
# Backup existing crontab
# ──────────────────────────────────────────────
backup_crontab() {
    mkdir -p "$CRON_BACKUP_DIR"
    local backup_file="$CRON_BACKUP_DIR/crontab-$(date +%Y%m%d-%H%M%S).bak"
    crontab -l 2>/dev/null > "$backup_file" || true
    print_status "Crontab backed up to: $backup_file"
}

# ──────────────────────────────────────────────
# Remove all lubuntu cron jobs
# ──────────────────────────────────────────────
remove_cron_jobs() {
    echo -e "\n${YELLOW}Removing all lubuntu-system-tools cron jobs...${NC}"
    backup_crontab

    local current
    current=$(crontab -l 2>/dev/null || true)
    if echo "$current" | grep -q "$CRON_TAG"; then
        echo "$current" | grep -v "$CRON_TAG" | crontab -
        print_status "All lubuntu-system-tools cron jobs removed."
    else
        print_info "No lubuntu-system-tools cron jobs found to remove."
    fi
    echo
}

# ──────────────────────────────────────────────
# Validate a cron expression (basic check)
# ──────────────────────────────────────────────
validate_cron_expr() {
    local expr="$1"
    # A valid cron expression has exactly 5 space-separated fields
    local field_count
    field_count=$(echo "$expr" | awk '{print NF}')
    if [ "$field_count" -ne 5 ]; then
        return 1
    fi
    return 0
}

# ──────────────────────────────────────────────
# Prompt user to pick a schedule
# ──────────────────────────────────────────────
pick_schedule() {
    local script_name="$1"
    echo -e "\n${CYAN}Choose a schedule for ${YELLOW}$script_name${CYAN}:${NC}"
    echo "  1) Hourly          (0 * * * *)"
    echo "  2) Daily at 2 AM   (0 2 * * *)"
    echo "  3) Daily at midnight (0 0 * * *)"
    echo "  4) Weekly (Sunday 3 AM) (0 3 * * 0)"
    echo "  5) Every 6 hours   (0 */6 * * *)"
    echo "  6) Every 30 minutes (*/30 * * * *)"
    echo "  7) Custom cron expression"
    echo -n "  Enter choice [1-7]: "
    read -r sched_choice

    case "$sched_choice" in
        1) CRON_EXPR="0 * * * *" ;;
        2) CRON_EXPR="0 2 * * *" ;;
        3) CRON_EXPR="0 0 * * *" ;;
        4) CRON_EXPR="0 3 * * 0" ;;
        5) CRON_EXPR="0 */6 * * *" ;;
        6) CRON_EXPR="*/30 * * * *" ;;
        7)
            echo -n "  Enter cron expression (e.g. '0 2 * * *'): "
            read -r CRON_EXPR
            if ! validate_cron_expr "$CRON_EXPR"; then
                print_error "Invalid cron expression. Expected 5 fields (min hour day month weekday)."
                return 1
            fi
            ;;
        *)
            print_warning "Invalid choice, using default: daily at 2 AM"
            CRON_EXPR="0 2 * * *"
            ;;
    esac
    return 0
}

# ──────────────────────────────────────────────
# Add a single cron job entry
# ──────────────────────────────────────────────
add_cron_job() {
    local cron_expr="$1"
    local script_path="$2"
    local log_file="$3"
    local needs_sudo="$4"

    local cmd
    if [ "$needs_sudo" = true ]; then
        cmd="$cron_expr sudo $script_path >> $log_file 2>&1 $CRON_TAG"
    else
        cmd="$cron_expr $script_path >> $log_file 2>&1 $CRON_TAG"
    fi

    # Append to existing crontab
    ( crontab -l 2>/dev/null; echo "$cmd" ) | crontab -
    print_status "Cron job added: $cron_expr  $(basename "$script_path")"
}

# ──────────────────────────────────────────────
# Interactive setup
# ──────────────────────────────────────────────
interactive_setup() {
    echo -e "\n${GREEN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Lubuntu System Tools - Cron Job Installer  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}\n"

    # Create log directory
    if [ ! -d "$LOG_DIR" ]; then
        sudo mkdir -p "$LOG_DIR"
        sudo chmod 755 "$LOG_DIR"
        print_status "Created log directory: $LOG_DIR"
    fi

    backup_crontab

    declare -A SCRIPT_MAP
    SCRIPT_MAP=(
        [1]="backup-manager.sh"
        [2]="disk-cleanup.sh"
        [3]="update-system.sh"
        [4]="ram-manager.sh"
        [5]="sys-info.sh"
        [6]="auto-maintenance.sh"
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
        if [ -z "$script_name" ]; then
            print_warning "Unknown selection: $key, skipping."
            continue
        fi

        script_path="$SCRIPTS_DIR/$script_name"
        if [ ! -f "$script_path" ]; then
            print_warning "$script_name not found at $script_path, skipping."
            continue
        fi

        if pick_schedule "$script_name"; then
            log_name="${script_name%.sh}.log"
            add_cron_job "$CRON_EXPR" "$script_path" "$LOG_DIR/$log_name" "${SUDO_MAP[$key]}"
            added=$((added + 1))
        fi
    done

    echo -e "\n${GREEN}╔══════════════════════════════════════════════╗${NC}"
    printf "${GREEN}║  Setup Complete! Added %-2s cron job(s).      ║${NC}\n" "$added"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
    echo
    print_info "View logs in: $LOG_DIR/"
    print_info "Edit cron jobs with: crontab -e"
    print_info "List lubuntu jobs: $0 --list"
    print_info "Remove all lubuntu jobs: $0 --remove"
    echo
}

# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────
main() {
    case "${1:-}" in
        --help)    show_help ;;
        --list)    list_cron_jobs ;;
        --remove)  remove_cron_jobs ;;
        "")        interactive_setup ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
