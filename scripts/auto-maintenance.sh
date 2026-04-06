#!/bin/bash

# Lubuntu System Tools - Auto Maintenance Script
# Runs all critical system maintenance tasks in one go
# Usage: ./auto-maintenance.sh [OPTIONS]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/var/log/lubuntu-tools"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
MAIN_LOG="$LOG_DIR/auto-maintenance-$TIMESTAMP.log"

# Task flags (all enabled by default)
RUN_BACKUP=true
RUN_CLEANUP=true
RUN_UPDATE=true
RUN_RAM=true
DRY_RUN=false

# Result tracking
TASKS_PASSED=0
TASKS_FAILED=0
FAILED_TASKS=()

# ──────────────────────────────────────────────
# Helper print functions (also write to log)
# ──────────────────────────────────────────────
log() { echo -e "$1" | tee -a "$MAIN_LOG"; }

print_status()  { log "${GREEN}[✓]${NC} $1"; }
print_warning() { log "${YELLOW}[!]${NC} $1"; }
print_error()   { log "${RED}[✗]${NC} $1"; }
print_info()    { log "${BLUE}[i]${NC} $1"; }

# ──────────────────────────────────────────────
# Help text
# ──────────────────────────────────────────────
show_help() {
    cat << EOF

${CYAN}Lubuntu Auto Maintenance Script${NC}

Runs backup, cleanup, system update, and RAM management in sequence.

USAGE:
    ./auto-maintenance.sh [OPTIONS]

OPTIONS:
    (none)       Run all maintenance tasks
    --dry-run    Preview what would happen without making changes
    --backup     Run only the backup task
    --cleanup    Run only the disk cleanup task
    --update     Run only the system update task
    --ram        Run only the RAM management task
    --help       Show this help message

EXAMPLES:
    ./scripts/auto-maintenance.sh              # Run all tasks
    ./scripts/auto-maintenance.sh --dry-run    # Preview changes
    ./scripts/auto-maintenance.sh --backup     # Backup only
    ./scripts/auto-maintenance.sh --cleanup    # Cleanup only

LOG FILES:
    Main log: $LOG_DIR/auto-maintenance-<timestamp>.log
    Per-task: $LOG_DIR/<task>.log

EOF
}

# ──────────────────────────────────────────────
# Ensure log directory exists
# ──────────────────────────────────────────────
setup_logging() {
    if [ ! -d "$LOG_DIR" ]; then
        sudo mkdir -p "$LOG_DIR"
        sudo chmod 755 "$LOG_DIR"
    fi
    touch "$MAIN_LOG"
}

# ──────────────────────────────────────────────
# Run a task script and track result
# ──────────────────────────────────────────────
run_task() {
    local name="$1"
    local script="$2"
    shift 2
    local extra_args=("$@")
    local task_log="$LOG_DIR/${name}.log"

    log "\n${CYAN}────────────────────────────────────────${NC}"
    log "${CYAN}Task: $name${NC}"
    log "${CYAN}────────────────────────────────────────${NC}"

    if [ ! -f "$script" ]; then
        print_warning "$script not found, skipping $name."
        TASKS_FAILED=$((TASKS_FAILED + 1))
        FAILED_TASKS+=("$name (script not found)")
        return
    fi

    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would run: $script ${extra_args[*]}"
        return
    fi

    local start_time
    start_time=$(date +%s)

    if "$script" "${extra_args[@]}" >> "$task_log" 2>&1; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_status "$name completed successfully (${duration}s)"
        TASKS_PASSED=$((TASKS_PASSED + 1))
    else
        print_error "$name FAILED - check $task_log for details"
        TASKS_FAILED=$((TASKS_FAILED + 1))
        FAILED_TASKS+=("$name")
    fi
}

# ──────────────────────────────────────────────
# Individual tasks
# ──────────────────────────────────────────────
task_backup() {
    run_task "backup" "$SCRIPT_DIR/backup-manager.sh"
}

task_cleanup() {
    if [ "$DRY_RUN" = true ]; then
        run_task "disk-cleanup" "$SCRIPT_DIR/disk-cleanup.sh" "--dry-run"
    else
        run_task "disk-cleanup" "$SCRIPT_DIR/disk-cleanup.sh"
    fi
}

task_update() {
    run_task "update-system" "$SCRIPT_DIR/update-system.sh"
}

task_ram() {
    # ram-manager.sh is interactive; pass non-interactive workaround via stdin
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would run: $SCRIPT_DIR/ram-manager.sh (non-interactive, skip cache clear)"
        return
    fi

    local task_log="$LOG_DIR/ram-manager.log"
    log "\n${CYAN}────────────────────────────────────────${NC}"
    log "${CYAN}Task: RAM Manager${NC}"
    log "${CYAN}────────────────────────────────────────${NC}"

    if [ ! -f "$SCRIPT_DIR/ram-manager.sh" ]; then
        print_warning "$SCRIPT_DIR/ram-manager.sh not found, skipping."
        TASKS_FAILED=$((TASKS_FAILED + 1))
        FAILED_TASKS+=("ram-manager (script not found)")
        return
    fi

    # Pass 'n' automatically so the cache-clear prompt is declined
    if echo "n" | "$SCRIPT_DIR/ram-manager.sh" >> "$task_log" 2>&1; then
        print_status "RAM Manager completed successfully"
        TASKS_PASSED=$((TASKS_PASSED + 1))
    else
        print_error "RAM Manager FAILED - check $task_log for details"
        TASKS_FAILED=$((TASKS_FAILED + 1))
        FAILED_TASKS+=("ram-manager")
    fi
}

# ──────────────────────────────────────────────
# Print summary report
# ──────────────────────────────────────────────
print_summary() {
    local total=$((TASKS_PASSED + TASKS_FAILED))
    echo -e "\n${GREEN}╔══════════════════════════════════════════════╗${NC}" | tee -a "$MAIN_LOG"
    echo -e "${GREEN}║          Maintenance Summary Report          ║${NC}" | tee -a "$MAIN_LOG"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}" | tee -a "$MAIN_LOG"
    log "  Date:    $(date)"
    log "  Log:     $MAIN_LOG"
    log "  Tasks:   $total total  |  ${GREEN}$TASKS_PASSED passed${NC}  |  ${RED}$TASKS_FAILED failed${NC}"

    if [ "${#FAILED_TASKS[@]}" -gt 0 ]; then
        log "\n  ${RED}Failed tasks:${NC}"
        for t in "${FAILED_TASKS[@]}"; do
            log "    - $t"
        done
    fi
    echo | tee -a "$MAIN_LOG"
}

# ──────────────────────────────────────────────
# Parse arguments
# ──────────────────────────────────────────────
parse_args() {
    # If any specific task flag is given, disable all others first
    local specific_task=false

    for arg in "$@"; do
        case "$arg" in
            --backup|--cleanup|--update|--ram) specific_task=true ;;
        esac
    done

    if [ "$specific_task" = true ]; then
        RUN_BACKUP=false
        RUN_CLEANUP=false
        RUN_UPDATE=false
        RUN_RAM=false
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)  DRY_RUN=true ;;
            --backup)   RUN_BACKUP=true ;;
            --cleanup)  RUN_CLEANUP=true ;;
            --update)   RUN_UPDATE=true ;;
            --ram)      RUN_RAM=true ;;
            --help)     show_help; exit 0 ;;
            *)
                echo -e "${RED}[✗]${NC} Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────
main() {
    parse_args "$@"
    setup_logging

    log "${GREEN}╔══════════════════════════════════════════════╗${NC}"
    log "${GREEN}║     Lubuntu Auto Maintenance Starting...     ║${NC}"
    log "${GREEN}╚══════════════════════════════════════════════╝${NC}"
    log "  Started: $(date)"
    log "  Log file: $MAIN_LOG"
    if [ "$DRY_RUN" = true ]; then
        log "\n${YELLOW}DRY RUN MODE - No changes will be made${NC}"
    fi

    [ "$RUN_BACKUP"  = true ] && task_backup
    [ "$RUN_CLEANUP" = true ] && task_cleanup
    [ "$RUN_UPDATE"  = true ] && task_update
    [ "$RUN_RAM"     = true ] && task_ram

    print_summary
}

main "$@"
