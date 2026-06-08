#!/bin/bash
# ========================================================================
# Lubuntu System Tools - Security Audit
# Copyright (C) 2026 William Hutton
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License.
# ========================================================================

set -e

# Security Audit Tool for Lubuntu
# Comprehensive security checks including SSH, firewall, sudo access, and file permissions
# Usage: ./security-audit.sh [OPTIONS]

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
AUDIT_LOG="$LOG_DIR/security-audit-$(date +%Y%m%d-%H%M%S).log"
SEVERITY_COUNT=0

# ──────────────────────────────────────────────
# Helper print functions
# ──────────────────────────────────────────────
print_status()  { echo -e "${GREEN}[✓]${NC} $1"; tee -a "$AUDIT_LOG" <<< "$1" > /dev/null; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; tee -a "$AUDIT_LOG" <<< "$1" > /dev/null; SEVERITY_COUNT=$((SEVERITY_COUNT + 1)); }
print_error()   { echo -e "${RED}[✗]${NC} $1"; tee -a "$AUDIT_LOG" <<< "$1" > /dev/null; SEVERITY_COUNT=$((SEVERITY_COUNT + 2)); }
print_info()    { echo -e "${BLUE}[i]${NC} $1"; tee -a "$AUDIT_LOG" <<< "$1" > /dev/null; }
print_section() { echo -e "\n${CYAN}── $1 ──────────────────────────────────────${NC}"; echo "" >> "$AUDIT_LOG"; echo "=== $1 ===" >> "$AUDIT_LOG"; }

# ──────────────────────────────────────────────
# Help text
# ──────────────────────────────────────────────
show_help() {
    cat << EOF

${CYAN}Lubuntu Security Audit Tool${NC}

Comprehensive security assessment of your system.

USAGE:
    ./security-audit.sh [OPTIONS]

OPTIONS:
    (none)           Run full security audit
    --ssh            Check SSH configuration
    --firewall       Check firewall status
    --sudo           Audit sudo access and permissions
    --users          Review user accounts and groups
    --permissions    Check critical file permissions
    --failed-logins  Show failed login attempts
    --open-ports     List open/listening ports
    --processes      Check running processes
    --quick          Run quick security check
    --help           Show this help message

EXAMPLES:
    ./scripts/security-audit.sh              # Full audit
    ./scripts/security-audit.sh --quick      # Quick check
    ./scripts/security-audit.sh --ssh        # SSH only
    ./scripts/security-audit.sh --firewall   # Firewall only

LOG FILES:
    Audit results: $LOG_DIR/security-audit-YYYYMMDD-HHMMSS.log

CRITICAL CHECKS:
    ✓ SSH key-based authentication enabled
    ✓ SSH password authentication disabled
    ✓ SSH root login disabled
    ✓ Firewall is active
    ✓ Sudo access properly restricted
    ✓ Critical file permissions secure
    ✓ Failed login monitoring
    ✓ Open ports analysis

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
    
    # Initialize log file
    echo "Security Audit Report - $(date '+%Y-%m-%d %H:%M:%S')" > "$AUDIT_LOG"
    echo "System: $(hostname) ($(uname -s))" >> "$AUDIT_LOG"
    echo "" >> "$AUDIT_LOG"
}

# ──────────────────────────────────────────────
# Check SSH Configuration
# ──────────────────────────────────────────────
audit_ssh() {
    print_section "SSH Configuration Security"
    
    SSH_CONFIG="/etc/ssh/sshd_config"
    
    if [ ! -f "$SSH_CONFIG" ]; then
        print_warning "SSH not installed or sshd_config not found"
        return
    fi
    
    # Check if SSH is running
    if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
        print_status "SSH service is running"
    else
        print_warning "SSH service is not running"
    fi
    
    # Check password authentication
    if grep -q "^PasswordAuthentication no" "$SSH_CONFIG"; then
        print_status "SSH password authentication is disabled"
    else
        print_error "SSH password authentication is ENABLED - Consider disabling it"
    fi
    
    # Check pubkey authentication
    if grep -q "^PubkeyAuthentication yes" "$SSH_CONFIG" || ! grep -q "^PubkeyAuthentication no" "$SSH_CONFIG"; then
        print_status "SSH public key authentication is enabled"
    else
        print_error "SSH public key authentication is disabled"
    fi
    
    # Check root login
    if grep -q "^PermitRootLogin no" "$SSH_CONFIG"; then
        print_status "SSH root login is disabled"
    else
        print_warning "SSH root login is allowed - Consider disabling it"
    fi
    
    # Check SSH port (non-standard is more secure)
    ssh_port=$(grep "^Port " "$SSH_CONFIG" | awk '{print $2}' || echo "22")
    if [ "$ssh_port" != "22" ]; then
        print_status "SSH is running on non-standard port: $ssh_port"
    else
        print_info "SSH is running on standard port 22"
    fi
    
    # Check empty password
    if grep -q "^PermitEmptyPasswords no" "$SSH_CONFIG"; then
        print_status "Empty SSH passwords are disabled"
    else
        print_warning "Empty passwords may be permitted"
    fi
    
    # Check X11 forwarding
    if grep -q "^X11Forwarding no" "$SSH_CONFIG"; then
        print_status "SSH X11 forwarding is disabled"
    else
        print_info "SSH X11 forwarding is enabled"
    fi
}

# ──────────────────────────────────────────────
# Check Firewall Status
# ──────────────────────────────────────────────
audit_firewall() {
    print_section "Firewall Configuration"
    
    # Check UFW (Uncomplicated Firewall)
    if command -v ufw &>/dev/null; then
        if sudo ufw status | grep -q "Status: active"; then
            print_status "UFW firewall is ACTIVE"
            echo -e "\n${BLUE}Current firewall rules:${NC}"
            sudo ufw status numbered | tail -n +3 | while read -r line; do
                echo "  $line"
                echo "  $line" >> "$AUDIT_LOG"
            done
        else
            print_error "UFW firewall is INACTIVE - Consider enabling it"
        fi
    else
        print_info "UFW not installed"
    fi
    
    # Check iptables
    if command -v iptables &>/dev/null; then
        rule_count=$(sudo iptables -L -n | grep "Chain" | wc -l)
        if [ "$rule_count" -gt 0 ]; then
            print_info "iptables has $rule_count chains configured"
        fi
    fi
}

# ──────────────────────────────────────────────
# Audit Sudo Access
# ──────────────────────────────────────────────
audit_sudo() {
    print_section "Sudo Access & Permissions"
    
    SUDOERS_DIR="/etc/sudoers.d"
    
    # Check if sudo is configured
    if [ -f "/etc/sudoers" ]; then
        print_status "Sudoers file exists"
        
        # Check for NOPASSWD entries (security risk)
        if sudo grep -r "NOPASSWD" /etc/sudoers /etc/sudoers.d/ 2>/dev/null | grep -v "^#"; then
            print_error "NOPASSWD sudo entries found - Users can run sudo without password!"
            sudo grep -r "NOPASSWD" /etc/sudoers /etc/sudoers.d/ 2>/dev/null | grep -v "^#" | while read -r line; do
                echo "  $line"
                echo "  $line" >> "$AUDIT_LOG"
            done
        else
            print_status "No NOPASSWD sudo entries found"
        fi
    fi
    
    # List users in sudo group
    echo -e "\n${BLUE}Users with sudo access:${NC}"
    if getent group sudo >/dev/null 2>&1; then
        getent group sudo | cut -d: -f4 | tr ',' '\n' | while read -r user; do
            if [ -n "$user" ]; then
                echo "  $user"
                echo "  $user" >> "$AUDIT_LOG"
            fi
        done
    else
        print_info "sudo group not found"
    fi
    
    # Check sudo log
    if [ -f "/var/log/auth.log" ]; then
        recent_sudo=$(grep "sudo.*COMMAND" /var/log/auth.log 2>/dev/null | tail -5 | wc -l)
        if [ "$recent_sudo" -gt 0 ]; then
            print_info "Recent sudo commands detected (last 5):"
            grep "sudo.*COMMAND" /var/log/auth.log 2>/dev/null | tail -5 | while read -r line; do
                echo "  $line"
                echo "  $line" >> "$AUDIT_LOG"
            done
        fi
    fi
}

# ──────────────────────────────────────────────
# Audit User Accounts
# ──────────────────────────────────────────────
audit_users() {
    print_section "User Accounts & Groups"
    
    echo -e "${BLUE}Active user accounts:${NC}"
    getent passwd | grep -v "nologin\|false" | cut -d: -f1,3 | while read -r user uid; do
        if [ "$uid" -ge 1000 ] 2>/dev/null; then
            echo "  $user (UID: $uid)"
            echo "  $user (UID: $uid)" >> "$AUDIT_LOG"
        fi
    done
    
    # Check for accounts without passwords
    echo -e "\n${BLUE}Checking for accounts without passwords:${NC}"
    if sudo awk -F: '($2 == "") { print $1 }' /etc/shadow 2>/dev/null | grep -v "^$"; then
        print_error "Accounts without passwords found!"
    else
        print_status "All accounts require passwords"
    fi
    
    # Check for UID 0 accounts (besides root)
    echo -e "\n${BLUE}Checking for additional UID 0 accounts:${NC}"
    awk -F: '($3 == 0) { print $1 }' /etc/passwd | while read -r user; do
        if [ "$user" != "root" ]; then
            print_error "Non-root account with UID 0 found: $user"
        fi
    done
    print_status "No suspicious UID 0 accounts found"
}

# ──────────────────────────────────────────────
# Check Critical File Permissions
# ──────────────────────────────────────────────
audit_permissions() {
    print_section "Critical File Permissions"
    
    # Files that should have restricted permissions
    declare -A critical_files=(
        ["/etc/passwd"]="644"
        ["/etc/shadow"]="640"
        ["/etc/group"]="644"
        ["/etc/gshadow"]="640"
        ["/root"]="700"
        ["/home"]="755"
    )
    
    for file in "${!critical_files[@]}"; do
        if [ -e "$file" ]; then
            perms=$(stat -c '%a' "$file")
            expected="${critical_files[$file]}"
            
            if [ "$perms" = "$expected" ]; then
                print_status "$file permissions: $perms (correct)"
            else
                print_warning "$file permissions: $perms (expected: $expected)"
            fi
        fi
    done
    
    # Check for world-writable files in critical directories
    echo -e "\n${BLUE}Checking for world-writable files in /etc:${NC}"
    world_writable=$(find /etc -type f -perm -002 2>/dev/null | head -10)
    if [ -n "$world_writable" ]; then
        print_warning "World-writable files found in /etc:"
        echo "$world_writable" | while read -r file; do
            echo "  $file"
            echo "  $file" >> "$AUDIT_LOG"
        done
    else
        print_status "No world-writable files in /etc"
    fi
}

# ──────────────────────────────────────────────
# Check Failed Login Attempts
# ──────────────────────────────────────────────
audit_failed_logins() {
    print_section "Failed Login Attempts"
    
    if [ -f "/var/log/auth.log" ]; then
        failed_count=$(grep "Failed password" /var/log/auth.log 2>/dev/null | wc -l)
        echo -e "${BLUE}Failed login attempts (total): $failed_count${NC}"
        
        if [ "$failed_count" -gt 0 ]; then
            print_warning "Multiple failed login attempts detected"
            echo -e "\n${BLUE}Recent failed attempts (last 10):${NC}"
            grep "Failed password" /var/log/auth.log 2>/dev/null | tail -10 | while read -r line; do
                echo "  $line"
                echo "  $line" >> "$AUDIT_LOG"
            done
        else
            print_status "No recent failed login attempts"
        fi
        
        # Check for brute force patterns (>5 failures from same IP in last hour)
        echo -e "\n${BLUE}Checking for brute force attempts:${NC}"
        brute_force=$(grep "Failed password" /var/log/auth.log 2>/dev/null | grep "$(date '+%b %d %H')" | awk '{print $11}' | sort | uniq -c | sort -rn | awk '$1 > 5 {print $2}' || true)
        if [ -n "$brute_force" ]; then
            print_error "Possible brute force attempts detected from:"
            echo "$brute_force" | while read -r ip; do
                echo "  $ip"
                echo "  $ip" >> "$AUDIT_LOG"
            done
        else
            print_status "No brute force patterns detected"
        fi
    else
        print_info "Auth log not available"
    fi
}

# ──────────────────────────────────────────────
# List Open Ports
# ──────────────────────────────────────────────
audit_open_ports() {
    print_section "Open & Listening Ports"
    
    echo -e "${BLUE}Services listening on network ports:${NC}"
    
    if command -v ss &>/dev/null; then
        ss -tlnp 2>/dev/null | grep -v "State\|tcp" | while read -r proto recv send local remote state pid_program; do
            echo "  $local - $pid_program"
            echo "  $local - $pid_program" >> "$AUDIT_LOG"
        done
    elif command -v netstat &>/dev/null; then
        netstat -tlnp 2>/dev/null | grep "LISTEN" | while read -r proto recv send local remote state pid_program; do
            echo "  $local"
        done
    else
        print_warning "Neither ss nor netstat found"
    fi
}

# ──────────────────────────────────────────────
# Check Running Processes
# ──────────────────────────────────────────────
audit_processes() {
    print_section "Running Processes"
    
    echo -e "${BLUE}Processes running as root:${NC}"
    ps -u root -o pid,user,command --no-headers 2>/dev/null | grep -v "^\s*[0-9]\+\s*root\s*\[" | head -10 | while read -r line; do
        echo "  $line"
        echo "  $line" >> "$AUDIT_LOG"
    done
    
    echo -e "\n${BLUE}Processes with elevated privileges (setuid):${NC}"
    find /usr/bin /usr/sbin -perm -4000 2>/dev/null | head -10 | while read -r file; do
        echo "  $file"
        echo "  $file" >> "$AUDIT_LOG"
    done
}

# ──────────────────────────────────────────────
# Quick Security Check
# ──────────────────────────────────────────────
quick_check() {
    print_section "Quick Security Check"
    
    audit_ssh
    audit_firewall
    audit_sudo
    
    echo -e "\n${CYAN}Quick Check Complete${NC}"
}

# ──────────────────────────────────────────────
# Full Audit
# ──────────────────────────────────────────────
full_audit() {
    audit_ssh
    audit_firewall
    audit_sudo
    audit_users
    audit_permissions
    audit_failed_logins
    audit_open_ports
    audit_processes
}

# ──────────────────────────────────────────────
# Print Summary
# ──────────────────────────────────────────────
print_summary() {
    echo -e "\n${CYAN}── Audit Summary ────────────────────────────────${NC}"
    
    if [ "$SEVERITY_COUNT" -eq 0 ]; then
        echo -e "${GREEN}✓ No critical security issues detected${NC}"
    elif [ "$SEVERITY_COUNT" -lt 3 ]; then
        echo -e "${YELLOW}⚠ Minor security issues found (Score: $SEVERITY_COUNT)${NC}"
    else
        echo -e "${RED}✗ Multiple security issues detected (Score: $SEVERITY_COUNT)${NC}"
    fi
    
    echo -e "\nAudit log saved to: ${BLUE}$AUDIT_LOG${NC}\n"
    echo "Audit Summary - Issues: $SEVERITY_COUNT" >> "$AUDIT_LOG"
}

# ──────────────────────────────────────────────
# Parse command-line arguments
# ──────────────────────────────────────────────
setup_logging

if [ $# -eq 0 ]; then
    full_audit
    print_summary
else
    case "$1" in
        --help)
            show_help
            ;;
        --ssh)
            audit_ssh
            ;;
        --firewall)
            audit_firewall
            ;;
        --sudo)
            audit_sudo
            ;;
        --users)
            audit_users
            ;;
        --permissions)
            audit_permissions
            ;;
        --failed-logins)
            audit_failed_logins
            ;;
        --open-ports)
            audit_open_ports
            ;;
        --processes)
            audit_processes
            ;;
        --quick)
            quick_check
            print_summary
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
fi
