#!/bin/bash
# ========================================================================
# Lubuntu System Tools - Bandwidth Monitor
# Copyright (C) 2026 William Hutton
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License.
# ========================================================================

set -e

# Bandwidth Monitor for Lubuntu and other Ubuntu based OS
# Real-time network usage monitoring, per-process bandwidth analysis, and historical logging
# Usage: ./bandwidth-monitor.sh [OPTIONS]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
LOG_DIR="/var/log/lubuntu-tools"
BANDWIDTH_LOG="$LOG_DIR/bandwidth-history-$(date +%Y%m%d).log"
REFRESH_INTERVAL=2
MONITOR_DURATION=0  # 0 = infinite

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

${CYAN}Lubuntu Bandwidth Monitor${NC}

Real-time network bandwidth monitoring and per-process analysis.

USAGE:
    ./bandwidth-monitor.sh [OPTIONS]

OPTIONS:
    (none)           Real-time bandwidth monitor (Ctrl+C to stop)
    --summary        Show network interface summary and exit
    --top-processes  Show top bandwidth-consuming processes
    --interface IF   Monitor specific interface (e.g., eth0, wlan0)
    --duration SECS  Monitor for N seconds then exit
    --log-only       Log current bandwidth and exit (no monitor)
    --history        Show bandwidth history from today
    --help           Show this help message

EXAMPLES:
    ./scripts/bandwidth-monitor.sh              # Real-time monitor
    ./scripts/bandwidth-monitor.sh --summary    # Quick overview
    ./scripts/bandwidth-monitor.sh --top-processes  # Top consumers
    ./scripts/bandwidth-monitor.sh --duration 60    # Monitor 60 seconds
    ./scripts/bandwidth-monitor.sh --history    # Today's history

LOG FILES:
    Daily history: $LOG_DIR/bandwidth-history-YYYYMMDD.log

DEPENDENCIES:
    - ip, cat (standard)
    - ss or netstat (for process analysis)
    - vnstat (optional for enhanced statistics)

EOF
}

# ──────────────────────────────────────────────
# Ensure log directory exists
# ──────────────────────────────────────────────
setup_logging() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || sudo mkdir -p "$LOG_DIR" 2>/dev/null || true
        sudo chmod 755 "$LOG_DIR" 2>/dev/null || true
    fi
}

# ──────────────────────────────────────────────
# Convert bytes to human-readable format
# ──────────────────────────────────────────────
format_bytes() {
    local bytes=$1
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes}B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$(( bytes / 1024 ))KB"
    elif [ "$bytes" -lt 1073741824 ]; then
        printf "%.2fMB" "$(echo "scale=2; $bytes / 1048576" | bc)"
    else
        printf "%.2fGB" "$(echo "scale=2; $bytes / 1073741824" | bc)"
    fi
}

# ──────────────────────────────────────────────
# Get network interfaces
# ──────────────────────────────────────────────
get_interfaces() {
    ip link show | grep -E "^[0-9]+:" | awk -F': ' '{print $2}' | sed 's/@.*//' | grep -v "^lo$"
}

# ──────────────────────────────────────────────
# Get current RX/TX bytes for interface
# ──────────────────────────────────────────────
get_interface_stats() {
    local iface=$1
    local rx_file="/sys/class/net/$iface/statistics/rx_bytes"
    local tx_file="/sys/class/net/$iface/statistics/tx_bytes"
    
    if [ -f "$rx_file" ] && [ -f "$tx_file" ]; then
        local rx=$(cat "$rx_file")
        local tx=$(cat "$tx_file")
        echo "$rx $tx"
    else
        echo "0 0"
    fi
}

# ──────────────────────────────────────────────
# Calculate bandwidth usage
# ──────────────────────────────────────────────
calculate_bandwidth() {
    local iface=$1
    local interval=${2:-2}
    
    # Get initial stats
    read -r rx1 tx1 < <(get_interface_stats "$iface")
    
    sleep "$interval"
    
    # Get final stats
    read -r rx2 tx2 < <(get_interface_stats "$iface")
    
    # Calculate differences (bytes per interval)
    local rx_diff=$((rx2 - rx1))
    local tx_diff=$((tx2 - tx1))
    
    # Convert to per-second rate
    local rx_rate=$((rx_diff / interval))
    local tx_rate=$((tx_diff / interval))
    
    echo "$rx_rate $tx_rate"
}

# ──────────────────────────────────────────────
# Show interface summary
# ──────────────────────────────────────────────
show_summary() {
    setup_logging
    
    echo -e "\n${CYAN}── Network Interface Summary ────────────────────${NC}\n"
    
    for iface in $(get_interfaces); do
        read -r rx tx < <(get_interface_stats "$iface")
        
        # Get IP address
        ip_addr=$(ip addr show "$iface" 2>/dev/null | grep "inet " | awk '{print $2}' | head -1)
        
        # Get interface status
        status=$(ip link show "$iface" | grep -o "UP\|DOWN" | head -1)
        
        if [ "$status" = "UP" ]; then
            status_color="$GREEN"
        else
            status_color="$YELLOW"
        fi
        
        echo -e "Interface: ${CYAN}${iface}${NC}"
        echo -e "  Status:       ${status_color}${status}${NC}"
        echo -e "  IP Address:   ${ip_addr:-N/A}"
        echo -e "  RX Total:     $(format_bytes "$rx")"
        echo -e "  TX Total:     $(format_bytes "$tx")"
        echo ""
    done
}

# ──────────────────────────────────────────────
# Real-time bandwidth monitor
# ──────────────────────────────────────────────
monitor_bandwidth() {
    local iface=${1:-""}
    local duration=${2:-0}
    
    # If no interface specified, monitor all active interfaces
    if [ -z "$iface" ]; then
        iface=$(get_interfaces | head -1)
        if [ -z "$iface" ]; then
            print_error "No active network interfaces found"
            return 1
        fi
    fi
    
    setup_logging
    
    echo -e "\n${CYAN}Monitoring bandwidth on ${iface}${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}\n"
    
    local start_time=$(date +%s)
    local total_rx=0
    local total_tx=0
    local samples=0
    
    while true; do
        read -r rx_rate tx_rate < <(calculate_bandwidth "$iface" "$REFRESH_INTERVAL")
        
        local rx_formatted=$(format_bytes "$rx_rate")
        local tx_formatted=$(format_bytes "$tx_rate")
        
        # Color code based on usage (alert on high bandwidth)
        local threshold=$((100 * 1024 * 1024))  # 100MB/s
        if [ "$((rx_rate + tx_rate))" -gt "$threshold" ]; then
            rate_color="$RED"
            alert="⚠️ HIGH"
        elif [ "$((rx_rate + tx_rate))" -gt $((50 * 1024 * 1024)) ]; then
            rate_color="$YELLOW"
            alert=""
        else
            rate_color="$GREEN"
            alert=""
        fi
        
        # Clear line and print stats
        printf "\r${CYAN}%s${NC} ${rate_color}↓ ${rx_formatted}/s  ↑ ${tx_formatted}/s${NC} %s     " \
            "$(date '+%H:%M:%S')" "$alert"
        
        # Accumulate totals
        total_rx=$((total_rx + rx_rate * REFRESH_INTERVAL))
        total_tx=$((total_tx + tx_rate * REFRESH_INTERVAL))
        samples=$((samples + 1))
        
        # Log to file periodically (every 30 samples = 60 seconds)
        if [ $((samples % 30)) -eq 0 ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') ${iface}: RX=$(format_bytes "$rx_rate")/s TX=$(format_bytes "$tx_rate")/s" >> "$BANDWIDTH_LOG"
        fi
        
        # Check if duration exceeded
        if [ "$duration" -gt 0 ]; then
            local elapsed=$(($(date +%s) - start_time))
            if [ "$elapsed" -ge "$duration" ]; then
                break
            fi
        fi
    done
    
    # Print summary
    echo -e "\n\n${CYAN}── Session Summary ──────────────────────────────${NC}"
    echo -e "  Duration:        $((samples * REFRESH_INTERVAL)) seconds"
    echo -e "  Total RX:        $(format_bytes "$total_rx")"
    echo -e "  Total TX:        $(format_bytes "$total_tx")"
    echo -e "  Avg RX/s:        $(format_bytes "$((total_rx / samples))")/s"
    echo -e "  Avg TX/s:        $(format_bytes "$((total_tx / samples))")/s"
    echo -e "  Log saved to:    ${BANDWIDTH_LOG}\n"
}

# ──────────────────────────────────────────────
# Show top bandwidth-consuming processes
# ──────────────────────────────────────────────
show_top_processes() {
    setup_logging
    
    echo -e "\n${CYAN}── Top Bandwidth Consumers ──────────────────────${NC}\n"
    
    if command -v ss &>/dev/null; then
        # Use ss (socket statistics)
        echo -e "${BLUE}Active network connections:${NC}\n"
        ss -tupn 2>/dev/null | tail -n +2 | sort -k3 -rn | head -15 | while read -r proto recv send local remote state puser pid; do
            # Extract PID and process name
            if [ -n "$pid" ]; then
                process_name=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
                echo -e "  ${MAGENTA}${process_name}${NC} (PID: $pid)"
                echo -e "    Protocol: $proto | Local: $local | Remote: $remote"
            fi
        done
    else
        print_warning "ss not found, trying netstat..."
        if command -v netstat &>/dev/null; then
            netstat -tupn 2>/dev/null | tail -n +3 | head -15 | while read -r proto recv send local remote state user pid_program; do
                echo -e "  $pid_program"
            done
        else
            print_error "Neither ss nor netstat found. Install net-tools: sudo apt install net-tools"
        fi
    fi
    
    echo ""
    echo -e "${BLUE}Using lsof for open connections:${NC}\n"
    if command -v lsof &>/dev/null; then
        lsof -i -P -n 2>/dev/null | grep -E "ESTABLISHED|LISTEN" | head -10 | awk '{print $1, $9}' | sort | uniq -c | sort -rn | while read -r count process user; do
            echo -e "  ${MAGENTA}${user}${NC}: $count connections to $process"
        done
    else
        print_warning "lsof not installed"
    fi
    
    echo ""
}

# ──────────────────────────────────────────────
# Log current bandwidth snapshot
# ──────────────────────────────────────────────
log_snapshot() {
    setup_logging
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') --- Bandwidth Snapshot ---" >> "$BANDWIDTH_LOG"
    
    for iface in $(get_interfaces); do
        read -r rx_rate tx_rate < <(calculate_bandwidth "$iface" 1)
        echo "  ${iface}: RX=$(format_bytes "$rx_rate")/s TX=$(format_bytes "$tx_rate")/s" >> "$BANDWIDTH_LOG"
    done
    
    print_status "Bandwidth snapshot logged to $BANDWIDTH_LOG"
}

# ──────────────────────────────────────────────
# Show bandwidth history
# ──────────────────────────────────────────────
show_history() {
    setup_logging
    
    echo -e "\n${CYAN}── Bandwidth History (Today) ────────────────────${NC}\n"
    
    if [ -f "$BANDWIDTH_LOG" ]; then
        tail -50 "$BANDWIDTH_LOG" | while read -r line; do
            echo "  $line"
        done
    else
        print_info "No bandwidth history yet. Run the monitor to generate logs."
    fi
    
    echo ""
}

# ──────────────────────────────────────────────
# Parse command-line arguments
# ──────────────────────────────────────────────
if [ $# -eq 0 ]; then
    monitor_bandwidth
else
    case "$1" in
        --help)
            show_help
            ;;
        --summary)
            show_summary
            ;;
        --top-processes)
            show_top_processes
            ;;
        --interface)
            if [ -n "$2" ]; then
                monitor_bandwidth "$2" "${3:-0}"
            else
                print_error "Interface name required"
                exit 1
            fi
            ;;
        --duration)
            if [ -n "$2" ]; then
                monitor_bandwidth "" "$2"
            else
                print_error "Duration in seconds required"
                exit 1
            fi
            ;;
        --log-only)
            log_snapshot
            ;;
        --history)
            show_history
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
fi
