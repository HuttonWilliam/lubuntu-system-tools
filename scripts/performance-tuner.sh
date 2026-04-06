#!/bin/bash

# System Performance Optimizer for Lubuntu
# Optimize system performance and resource usage
# Usage: ./performance-tuner.sh [--optimize] [--report] [--cpu GOVERNOR] [--reset] [--help]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Dry-run flag
DRY_RUN=false

# Function to display help
show_help() {
    cat << EOF
System Performance Optimizer - Tune Lubuntu for better performance

USAGE:
    ./performance-tuner.sh [OPTIONS]

OPTIONS:
    --optimize          Run full optimization (CPU, swap, I/O, cache)
    --report            Generate a performance report
    --cpu GOVERNOR      Set CPU governor: performance | powersave | ondemand | schedutil
    --swap VALUE        Set swappiness (0-100, default kernel value is 60)
    --reset             Restore default system settings
    --dry-run           Show what would change without applying changes
    --help              Display this help message

EXAMPLES:
    ./performance-tuner.sh                   # Show current performance stats
    ./performance-tuner.sh --optimize        # Run optimization
    ./performance-tuner.sh --report          # Generate performance report
    ./performance-tuner.sh --cpu powersave   # Change CPU governor
    ./performance-tuner.sh --swap 10         # Set swappiness to 10
    ./performance-tuner.sh --reset           # Restore default settings
    ./performance-tuner.sh --dry-run --optimize  # Preview optimizations

NOTES:
    - Most optimization steps require sudo
    - Use --dry-run to preview changes before applying them
    - Use --reset to undo optimizations and return to defaults

EOF
}

# Print helpers
print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error()  { echo -e "${RED}[✗]${NC} $1"; }
print_info()   { echo -e "${BLUE}[i]${NC} $1"; }

# Apply or preview a change
apply() {
    local description="$1"
    shift
    if [ "$DRY_RUN" = true ]; then
        print_warning "[DRY-RUN] Would run: $*"
    else
        if "$@"; then
            print_status "$description"
        else
            print_warning "Could not apply: $description"
        fi
    fi
}

# ─── Performance Metrics ────────────────────────────────────────────────────

show_metrics() {
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Lubuntu System Performance Optimizer ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}── CPU ─────────────────────────────────────${NC}"

    # CPU model
    local cpu_model
    cpu_model=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs || echo "Unknown")
    echo -e "  Model:        ${cpu_model}"

    # CPU governor (per core, show unique values)
    if [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
        local governors
        governors=$(sort -u /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null | tr '\n' ' ' || echo "N/A")
        echo -e "  Governor:     ${governors}"
    fi

    # CPU usage
    local cpu_idle
    cpu_idle=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $8}' | tr -d '%id,' || echo "N/A")
    if [ -n "$cpu_idle" ] && [ "$cpu_idle" != "N/A" ]; then
        local cpu_used
        cpu_used=$(echo "$cpu_idle" | awk '{printf "%.1f", 100 - $1}')
        echo -e "  Usage:        ${cpu_used}%"
    fi

    echo ""
    echo -e "${CYAN}── Memory ──────────────────────────────────${NC}"
    free -h | grep -E "Mem|Swap" | while IFS= read -r line; do
        echo "  $line"
    done

    echo ""
    echo -e "${CYAN}── Swappiness ──────────────────────────────${NC}"
    local swappiness
    swappiness=$(cat /proc/sys/vm/swappiness 2>/dev/null || echo "N/A")
    echo -e "  vm.swappiness: ${swappiness}"

    echo ""
    echo -e "${CYAN}── I/O Scheduler ───────────────────────────${NC}"
    for dev in /sys/block/sd* /sys/block/nvme* /sys/block/mmcblk*; do
        [ -e "$dev/queue/scheduler" ] || continue
        local sched
        sched=$(cat "$dev/queue/scheduler" 2>/dev/null || echo "N/A")
        echo -e "  $(basename "$dev"):  ${sched}"
    done

    echo ""
    echo -e "${CYAN}── Load Average ────────────────────────────${NC}"
    echo -e "  $(uptime | awk -F'load average:' '{print "Load:" $2}')"

    echo ""
    echo -e "${CYAN}── Top 5 Processes by CPU ──────────────────${NC}"
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu 2>/dev/null | head -n 6 | while IFS= read -r line; do
        echo "  $line"
    done

    echo ""
}

# ─── Optimization Steps ────────────────────────────────────────────────────

optimize_cpu() {
    echo -e "${YELLOW}Optimizing CPU governor...${NC}"
    if [ ! -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
        print_info "cpufreq not available on this system."
        return
    fi
    # Use schedutil if available, otherwise ondemand (better than performance for battery life)
    local target="schedutil"
    if ! grep -qr "schedutil" /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null; then
        target="ondemand"
    fi
    for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        apply "Set CPU governor to $target" bash -c "echo '$target' | sudo tee '$gov' > /dev/null"
    done
}

optimize_swappiness() {
    echo -e "${YELLOW}Optimizing swappiness...${NC}"
    # Lower swappiness reduces swap usage, better for systems with >= 1 GB RAM
    apply "Set vm.swappiness=10" bash -c "echo 10 | sudo tee /proc/sys/vm/swappiness > /dev/null"
    if [ "$DRY_RUN" = false ]; then
        # Persist across reboots
        if ! grep -q "vm.swappiness" /etc/sysctl.conf 2>/dev/null; then
            apply "Persist swappiness in /etc/sysctl.conf" bash -c "echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf > /dev/null"
        else
            apply "Update swappiness in /etc/sysctl.conf" sudo sed -i 's/^vm.swappiness=.*/vm.swappiness=10/' /etc/sysctl.conf
        fi
    fi
}

optimize_io_scheduler() {
    echo -e "${YELLOW}Optimizing I/O scheduler...${NC}"
    for dev in /sys/block/sd* /sys/block/nvme* /sys/block/mmcblk*; do
        [ -e "$dev/queue/scheduler" ] || continue
        local devname
        devname=$(basename "$dev")
        # Use mq-deadline for HDDs/SSDs; bfq is good for responsiveness on older hardware
        local available
        available=$(cat "$dev/queue/scheduler" 2>/dev/null || echo "")
        if echo "$available" | grep -q "mq-deadline"; then
            apply "Set I/O scheduler to mq-deadline for $devname" bash -c "echo 'mq-deadline' | sudo tee '$dev/queue/scheduler' > /dev/null"
        elif echo "$available" | grep -q "deadline"; then
            apply "Set I/O scheduler to deadline for $devname" bash -c "echo 'deadline' | sudo tee '$dev/queue/scheduler' > /dev/null"
        else
            print_info "No preferred scheduler available for $devname, leaving as-is."
        fi
    done
}

clear_memory_cache() {
    echo -e "${YELLOW}Clearing memory caches...${NC}"
    apply "Sync filesystem buffers" sync
    apply "Drop page cache, dentries and inodes" bash -c "echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null"
}

disable_unnecessary_services() {
    echo -e "${YELLOW}Checking unnecessary background services...${NC}"

    # Services that are generally safe to disable on a desktop Lubuntu install
    local services=(
        "cups-browsed"      # Network printer discovery – disable if no network printers
        "ModemManager"      # Mobile broadband – disable if no modem
        "avahi-daemon"      # mDNS/Zeroconf – disable if not needed
    )

    for svc in "${services[@]}"; do
        local state
        state=$(systemctl is-active "$svc" 2>/dev/null || echo "inactive")
        if [ "$state" = "active" ]; then
            print_info "$svc is running. To disable: sudo systemctl disable --now $svc"
        fi
    done

    print_status "Service audit complete. Review suggestions above and disable as needed."
}

run_optimize() {
    echo ""
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}DRY-RUN MODE — No changes will be applied${NC}\n"
    fi

    optimize_cpu
    echo ""
    optimize_swappiness
    echo ""
    optimize_io_scheduler
    echo ""
    clear_memory_cache
    echo ""
    disable_unnecessary_services
    echo ""

    if [ "$DRY_RUN" = false ]; then
        print_status "Optimization complete!"
    else
        print_info "Dry-run complete. Run without --dry-run to apply changes."
    fi
}

# ─── Performance Report ────────────────────────────────────────────────────

generate_report() {
    local report_file="/tmp/perf-report-$(date +%Y%m%d-%H%M%S).txt"

    {
        echo "========================================="
        echo " Lubuntu Performance Report"
        echo " Generated: $(date)"
        echo "========================================="
        echo ""
        echo "--- Hostname / OS ---"
        uname -a
        lsb_release -a 2>/dev/null || true

        echo ""
        echo "--- CPU ---"
        grep -E "model name|cpu MHz|cpu cores" /proc/cpuinfo | sort -u

        echo ""
        echo "--- CPU Governor ---"
        cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null | sort -u || echo "N/A"

        echo ""
        echo "--- Memory ---"
        free -h

        echo ""
        echo "--- Swap / Swappiness ---"
        swapon --show 2>/dev/null || echo "No swap active"
        echo "vm.swappiness = $(cat /proc/sys/vm/swappiness 2>/dev/null)"

        echo ""
        echo "--- Disk I/O Schedulers ---"
        for dev in /sys/block/sd* /sys/block/nvme* /sys/block/mmcblk*; do
            [ -e "$dev/queue/scheduler" ] || continue
            echo "$(basename "$dev"): $(cat "$dev/queue/scheduler")"
        done

        echo ""
        echo "--- Disk Usage ---"
        df -h --output=source,size,used,avail,pcent,target | grep -v tmpfs

        echo ""
        echo "--- Load Average & Uptime ---"
        uptime

        echo ""
        echo "--- Top 10 Processes by CPU ---"
        ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 11

        echo ""
        echo "--- Top 10 Processes by Memory ---"
        ps -eo pid,comm,%cpu,%mem --sort=-%mem | head -n 11

        echo ""
        echo "--- Failed Services ---"
        systemctl --failed --no-legend 2>/dev/null || echo "None"

        echo ""
        echo "========================================="
        echo " End of Report"
        echo "========================================="
    } > "$report_file"

    print_status "Report saved to: ${report_file}"
    echo ""
    cat "$report_file"
}

# ─── Set CPU Governor ──────────────────────────────────────────────────────

set_cpu_governor() {
    local governor="$1"
    local valid_governors=("performance" "powersave" "ondemand" "schedutil" "conservative")
    local valid=false

    for g in "${valid_governors[@]}"; do
        [ "$g" = "$governor" ] && valid=true && break
    done

    if [ "$valid" = false ]; then
        print_error "Invalid CPU governor: '$governor'"
        echo "  Valid options: ${valid_governors[*]}"
        exit 1
    fi

    if [ ! -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
        print_error "cpufreq interface not found. Cannot set CPU governor."
        exit 1
    fi

    echo -e "${YELLOW}Setting CPU governor to '${governor}'...${NC}"
    for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        apply "Set governor to $governor" bash -c "echo '$governor' | sudo tee '$gov' > /dev/null"
    done
}

# ─── Set Swappiness ────────────────────────────────────────────────────────

set_swappiness() {
    local value="$1"

    if ! [[ "$value" =~ ^[0-9]+$ ]] || [ "$value" -lt 0 ] || [ "$value" -gt 100 ]; then
        print_error "Swappiness must be an integer between 0 and 100."
        exit 1
    fi

    echo -e "${YELLOW}Setting vm.swappiness to ${value}...${NC}"
    apply "Set vm.swappiness=$value" bash -c "echo '$value' | sudo tee /proc/sys/vm/swappiness > /dev/null"

    if [ "$DRY_RUN" = false ]; then
        if grep -q "^vm.swappiness" /etc/sysctl.conf 2>/dev/null; then
            apply "Update swappiness in /etc/sysctl.conf" sudo sed -i "s/^vm.swappiness=.*/vm.swappiness=${value}/" /etc/sysctl.conf
        else
            apply "Persist swappiness in /etc/sysctl.conf" bash -c "echo 'vm.swappiness=${value}' | sudo tee -a /etc/sysctl.conf > /dev/null"
        fi
    fi
}

# ─── Reset to Defaults ─────────────────────────────────────────────────────

reset_defaults() {
    echo -e "${YELLOW}Restoring default system settings...${NC}"

    # Restore CPU governor to ondemand
    if [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
        for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            apply "Reset CPU governor to ondemand" bash -c "echo 'ondemand' | sudo tee '$gov' > /dev/null"
        done
    fi

    # Restore swappiness to kernel default (60)
    apply "Reset vm.swappiness to 60" bash -c "echo 60 | sudo tee /proc/sys/vm/swappiness > /dev/null"

    if [ "$DRY_RUN" = false ]; then
        if grep -q "^vm.swappiness" /etc/sysctl.conf 2>/dev/null; then
            apply "Remove swappiness override from /etc/sysctl.conf" sudo sed -i '/^vm.swappiness=/d' /etc/sysctl.conf
        fi
    fi

    print_status "Default settings restored."
}

# ─── Main ──────────────────────────────────────────────────────────────────

main() {
    local mode="stats"
    local cpu_governor=""
    local swap_value=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --optimize)
                mode="optimize"
                shift
                ;;
            --report)
                mode="report"
                shift
                ;;
            --cpu)
                mode="cpu"
                if [[ -n "${2:-}" && "${2}" != --* ]]; then
                    cpu_governor="$2"
                    shift
                else
                    print_error "--cpu requires a governor name (e.g. powersave)"
                    exit 1
                fi
                shift
                ;;
            --swap)
                mode="swap"
                if [[ -n "${2:-}" && "${2}" != --* ]]; then
                    swap_value="$2"
                    shift
                else
                    print_error "--swap requires a value (0-100)"
                    exit 1
                fi
                shift
                ;;
            --reset)
                mode="reset"
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    case "$mode" in
        stats)    show_metrics ;;
        optimize) show_metrics; run_optimize ;;
        report)   generate_report ;;
        cpu)      set_cpu_governor "$cpu_governor" ;;
        swap)     set_swappiness "$swap_value" ;;
        reset)    reset_defaults ;;
    esac
}

main "$@"
