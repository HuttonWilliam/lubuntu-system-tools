#!/bin/bash
# ========================================================================
# Lubuntu System Tools - Network Health Diagnostics
# Copyright (C) 2026 William Hutton
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License.
# ========================================================================

set -e

# Network Health Monitor for Lubuntu
# Performs speed tests, latency checks, DNS validation, and connection stability analysis
# Usage: ./network-health.sh [OPTIONS]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PING_TIMEOUT=5
PING_COUNT=10
DNS_SERVERS=("8.8.8.8" "1.1.1.1" "208.67.222.222")
TEST_HOSTS=("google.com" "cloudflare.com" "github.com")
LOG_DIR="/var/log/lubuntu-tools"
LOG_FILE="$LOG_DIR/network-health-$(date +%Y%m%d-%H%M%S).log"

# ──────────────────────────────────────────────
# Helper print functions
# ──────────────────────────────────────────────
print_status()  { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error()   { echo -e "${RED}[✗]${NC} $1"; }
print_info()    { echo -e "${BLUE}[i]${NC} $1"; }

log_output() { echo -e "$1" | tee -a "$LOG_FILE"; }

# ──────────────────────────────────────────────
# Help text
# ──────────────────────────────────────────────
show_help() {
    cat << EOF

${CYAN}Lubuntu Network Health Diagnostic Tool${NC}

Comprehensive network diagnostics including latency, DNS, speed tests, and stability.

USAGE:
    ./network-health.sh [OPTIONS]

OPTIONS:
    (none)           Run all diagnostics
    --quick          Quick connectivity check only
    --latency        Test latency to multiple hosts
    --dns            Test DNS resolver functionality
    --speed          Perform speed test (requires speedtest-cli)
    --stability      Run 5-minute stability test
    --interface      Show detailed network interface info
    --routes         Display routing table
    --help           Show this help message

EXAMPLES:
    ./scripts/network-health.sh           # Full diagnostics
    ./scripts/network-health.sh --quick   # Quick check
    ./scripts/network-health.sh --speed   # Speed test only

LOG FILES:
    Results saved to: $LOG_DIR/network-health-<timestamp>.log

DEPENDENCIES:
    - ping, curl (standard)
    - speedtest-cli (optional for speed tests)
    - mtr (optional for advanced routing diagnostics)

EOF
}

# ──────────────────────────────────────────────
# Ensure log directory exists
# ──────────────────────────────────────────────
setup_logging() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || sudo mkdir -p "$LOG_DIR"
        sudo chmod 755 "$LOG_DIR" 2>/dev/null || true
    fi
}

# ──────────────────────────────────────────────
# Check if connected to internet
# ──────────────────────────────────────────────
check_connectivity() {
    echo -e "\n${CYAN}── Connection Status ───────────────────────────────${NC}"
    log_output "=== NETWORK CONNECTIVITY CHECK ===" 
    
    if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        print_status "Internet connection: ONLINE"
        log_output "✓ Internet connection active"
        return 0
    else
        print_error "Internet connection: OFFLINE"
        log_output "✗ No internet connection detected"
        return 1
    fi
}

# ──────────────────────────────────────────────
# Get network interfaces
# ──────────────────────────────────────────────
show_interfaces() {
    echo -e "\n${CYAN}── Network Interfaces ──────────────────────────────${NC}"
    log_output "=== NETWORK INTERFACES ===" 
    
    if command -v ip &>/dev/null; then
        ip link show | grep -E "^[0-9]+:" | while read -r line; do
            iface=$(echo "$line" | awk '{print $2}' | tr -d ':')
            status=$(echo "$line" | grep -o "UP\|DOWN" | head -1)
            
            # Get IP address if UP
            if [ "$status" = "UP" ]; then
                ip_addr=$(ip addr show "$iface" | grep "inet " | awk '{print $2}' | head -1)
                echo -e "  ${GREEN}${iface}${NC}: UP (${ip_addr:-No IP})"
                log_output "  $iface: UP ($ip_addr)"
            else
                echo -e "  ${YELLOW}${iface}${NC}: DOWN"
                log_output "  $iface: DOWN"
            fi
        done
    else
        ifconfig 2>/dev/null | grep -E "^[a-z]" | awk '{print $1}'
    fi
}

# ──────────────────────────────────────────────
# Test latency to multiple hosts
# ──────────────────────────────────────────────
test_latency() {
    echo -e "\n${CYAN}── Latency Test ────────────────────────────────────${NC}"
    log_output "=== LATENCY TEST ===" 
    
    for host in "${TEST_HOSTS[@]}"; do
        avg_latency=$(ping -c "$PING_COUNT" -W "$PING_TIMEOUT" "$host" 2>/dev/null | tail -1 | awk -F'/' '{print $5}')
        
        if [ -n "$avg_latency" ]; then
            # Color code latency
            if (( $(echo "$avg_latency < 50" | bc -l) )); then
                color="$GREEN"
                quality="Excellent"
            elif (( $(echo "$avg_latency < 100" | bc -l) )); then
                color="$YELLOW"
                quality="Good"
            else
                color="$RED"
                quality="Poor"
            fi
            
            echo -e "  $host: ${color}${avg_latency}ms${NC} ($quality)"
            log_output "  $host: ${avg_latency}ms ($quality)"
        else
            print_warning "$host: No response (unreachable)"
            log_output "  $host: No response"
        fi
    done
}

# ──────────────────────────────────────────────
# Test DNS resolution
# ──────────────────────────────────────────────
test_dns() {
    echo -e "\n${CYAN}── DNS Resolution Test ────────────────────────────${NC}"
    log_output "=== DNS RESOLUTION TEST ===" 
    
    # Show current DNS servers
    echo -e "${BLUE}Current DNS servers:${NC}"
    if [ -f /etc/resolv.conf ]; then
        grep "^nameserver" /etc/resolv.conf | awk '{print "  " $2}' | while read -r ns; do
            echo -e "$ns"
            log_output "$ns"
        done
    fi
    
    # Test DNS lookups
    echo -e "\n${BLUE}Testing DNS resolution:${NC}"
    for host in "${TEST_HOSTS[@]}"; do
        result=$(dig +short "$host" 2>/dev/null | head -1)
        if [ -n "$result" ]; then
            echo -e "  ${GREEN}✓${NC} $host → $result"
            log_output "  ✓ $host → $result"
        else
            echo -e "  ${RED}✗${NC} $host (Failed to resolve)"
            log_output "  ✗ $host (Failed to resolve)"
        fi
    done
    
    # Test public DNS servers
    echo -e "\n${BLUE}Testing external DNS servers:${NC}"
    for dns in "${DNS_SERVERS[@]}"; do
        result=$(dig @"$dns" google.com +short 2>/dev/null | head -1)
        if [ -n "$result" ]; then
            echo -e "  ${GREEN}✓${NC} $dns responsive"
            log_output "  ✓ $dns responsive"
        else
            echo -e "  ${RED}✗${NC} $dns unreachable"
            log_output "  ✗ $dns unreachable"
        fi
    done
}

# ──────────────────────────────────────────────
# Run speed test (requires speedtest-cli)
# ──────────────────────────────────────────────
run_speed_test() {
    echo -e "\n${CYAN}── Speed Test ──────────────────────────────────────${NC}"
    log_output "=== SPEED TEST ===" 
    
    if ! command -v speedtest-cli &>/dev/null; then
        print_warning "speedtest-cli not installed. Install with: pip install speedtest-cli"
        log_output "speedtest-cli not installed"
        return
    fi
    
    print_info "Running speed test (this may take 1-2 minutes)..."
    log_output "Running speed test..."
    
    speedtest-cli --simple 2>/dev/null | while read -r line; do
        echo "  $line"
        log_output "  $line"
    done || print_warning "Speed test failed"
}

# ──────────────────────────────────────────────
# Stability test - monitor connection over time
# ──────────────────────────────────────────────
test_stability() {
    echo -e "\n${CYAN}── Stability Test (5 minutes) ──────────────────────${NC}"
    log_output "=== STABILITY TEST ===" 
    
    local success_count=0
    local total_count=0
    local latencies=()
    
    print_info "Testing connection stability over 5 minutes..."
    
    for i in {1..30}; do
        echo -ne "\r  Progress: $i/30 pings (${success_count} successful)"
        
        latency=$(ping -c 1 -W 2 8.8.8.8 2>/dev/null | grep "time=" | awk -F'=' '{print $4}' | awk '{print $1}')
        
        if [ -n "$latency" ]; then
            success_count=$((success_count + 1))
            latencies+=("$latency")
        fi
        
        total_count=$((total_count + 1))
        sleep 10
    done
    
    echo -e "\n"
    
    # Calculate statistics
    local success_rate=$((success_count * 100 / total_count))
    echo "  Success rate: ${success_count}/${total_count} (${success_rate}%)"
    log_output "Success rate: ${success_count}/${total_count} (${success_rate}%)"
    
    if [ ${#latencies[@]} -gt 0 ]; then
        local avg=$(printf '%.0f' "$(echo "${latencies[@]}" | awk '{for(i=1;i<=NF;i++)sum+=$i}END{print sum/NF}')")
        echo "  Average latency: ${avg}ms"
        log_output "Average latency: ${avg}ms"
    fi
    
    if [ "$success_rate" -ge 95 ]; then
        print_status "Connection is stable"
        log_output "✓ Connection is stable"
    else
        print_warning "Connection drops detected"
        log_output "! Connection drops detected"
    fi
}

# ──────────────────────────────────────────────
# Show routing table
# ──────────────────────────────────────────────
show_routes() {
    echo -e "\n${CYAN}── Routing Table ───────────────────────────────────${NC}"
    log_output "=== ROUTING TABLE ===" 
    
    if command -v ip &>/dev/null; then
        ip route show | while read -r line; do
            echo "  $line"
            log_output "  $line"
        done
    else
        netstat -rn | tail -n +3 | while read -r line; do
            echo "  $line"
            log_output "  $line"
        done
    fi
}

# ──────────────────────────────────────────────
# Quick connectivity check
# ──────────────────────────────────────────────
quick_check() {
    setup_logging
    log_output ""
    log_output "=== QUICK NETWORK CHECK ==="
    
    if check_connectivity; then
        show_interfaces
        test_latency
        echo -e "\n${GREEN}Network appears to be functioning normally.${NC}"
        log_output "✓ Quick check completed"
    else
        echo -e "\n${RED}Network is not responding. Check your connection.${NC}"
        log_output "✗ No network connection"
    fi
}

# ──────────────────────────────────────────────
# Full diagnostics
# ──────────────────────────────────────────────
full_diagnostics() {
    setup_logging
    log_output ""
    log_output "=== FULL NETWORK DIAGNOSTICS ==="
    
    show_interfaces
    
    if check_connectivity; then
        test_latency
        test_dns
        test_stability
        show_routes
        print_status "Full diagnostics completed"
    else
        print_error "Cannot proceed - no internet connection"
    fi
    
    echo -e "\n${BLUE}Results saved to: $LOG_FILE${NC}"
    log_output ""
    log_output "=== END OF REPORT ==="
}

# ──────────────────────────────────────────────
# Parse command-line arguments
# ──────────────────────────────────────────────
if [ $# -eq 0 ]; then
    full_diagnostics
else
    setup_logging
    
    case "$1" in
        --help)
            show_help
            ;;
        --quick)
            quick_check
            ;;
        --latency)
            log_output "=== LATENCY TEST ===" 
            test_latency
            echo -e "\n${BLUE}Results saved to: $LOG_FILE${NC}"
            ;;
        --dns)
            log_output "=== DNS TEST ===" 
            test_dns
            echo -e "\n${BLUE}Results saved to: $LOG_FILE${NC}"
            ;;
        --speed)
            log_output "=== SPEED TEST ===" 
            run_speed_test
            echo -e "\n${BLUE}Results saved to: $LOG_FILE${NC}"
            ;;
        --stability)
            log_output "=== STABILITY TEST ===" 
            test_stability
            echo -e "\n${BLUE}Results saved to: $LOG_FILE${NC}"
            ;;
        --interface)
            log_output "=== INTERFACE INFO ===" 
            show_interfaces
            echo -e "\n${BLUE}Results saved to: $LOG_FILE${NC}"
            ;;
        --routes)
            log_output "=== ROUTING TABLE ===" 
            show_routes
            echo -e "\n${BLUE}Results saved to: $LOG_FILE${NC}"
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
fi
