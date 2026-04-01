#!/bin/bash

# Disk Cleanup Utility for Lubuntu
# Removes temporary files, cache, logs, and reclaims disk space
# Usage: ./disk-cleanup.sh [--dry-run] [--help]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
DRY_RUN=false
TOTAL_FREED=0

# Function to display help
show_help() {
    cat << EOF
Disk Cleanup Utility - Remove temporary files and reclaim disk space

USAGE:
    ./disk-cleanup.sh [OPTIONS]

OPTIONS:
    --dry-run    Show what would be deleted without actually deleting
    --help       Display this help message

EXAMPLES:
    ./disk-cleanup.sh              # Run cleanup
    ./disk-cleanup.sh --dry-run    # Preview changes first

CLEANUP TARGETS:
    - Temporary files (/tmp, /var/tmp)
    - Package manager cache (apt, snap)
    - Old log files (>30 days)
    - Thumbnail cache
    - Trash bin

EOF
}

# Function to print status messages
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Function to get human-readable file size
format_size() {
    numfmt --to=iec-i --suffix=B --format="%.2f" "$1" 2>/dev/null || echo "$1 bytes"
}

# Function to cleanup temporary files
cleanup_temp() {
    echo -e "\n${YELLOW}Cleaning temporary files...${NC}"
    
    for dir in /tmp /var/tmp; do
        if [ -d "$dir" ]; then
            size=$(du -sb "$dir" 2>/dev/null | cut -f1)
            if [ "$DRY_RUN" = true ]; then
                print_warning "Would delete contents of $dir ($(format_size "$size"))"
            else
                sudo find "$dir" -type f -atime +7 -delete 2>/dev/null || true
                print_status "Cleaned $dir"
                TOTAL_FREED=$((TOTAL_FREED + size))
            fi
        fi
    done
}

# Function to cleanup package manager cache
cleanup_package_cache() {
    echo -e "\n${YELLOW}Cleaning package manager cache...${NC}"
    
    if command -v apt-get &> /dev/null; then
        size=$(du -sb /var/cache/apt 2>/dev/null | cut -f1)
        if [ "$DRY_RUN" = true ]; then
            print_warning "Would clean apt cache ($(format_size "$size"))"
        else
            sudo apt-get clean 2>/dev/null
            print_status "Cleaned apt cache"
            TOTAL_FREED=$((TOTAL_FREED + size))
        fi
    fi
    
    if command -v snap &> /dev/null; then
        size=$(du -sb /var/lib/snapd/cache 2>/dev/null | cut -f1)
        if [ "$DRY_RUN" = true ]; then
            print_warning "Would clean snap cache ($(format_size "$size"))"
        else
            sudo rm -rf /var/lib/snapd/cache/* 2>/dev/null || true
            print_status "Cleaned snap cache"
            TOTAL_FREED=$((TOTAL_FREED + size))
        fi
    fi
}

# Function to cleanup old log files
cleanup_logs() {
    echo -e "\n${YELLOW}Cleaning old log files...${NC}"
    
    if [ -d /var/log ]; then
        size=$(find /var/log -type f -mtime +30 -exec du -sb {} \; 2>/dev/null | awk '{sum+=$1} END {print sum}')
        if [ "$DRY_RUN" = true ]; then
            print_warning "Would delete log files older than 30 days ($(format_size "${size:-0}"))"
        else
            sudo find /var/log -type f -mtime +30 -delete 2>/dev/null || true
            print_status "Cleaned old log files"
            TOTAL_FREED=$((TOTAL_FREED + size))
        fi
    fi
}

# Function to cleanup thumbnail cache
cleanup_thumbnails() {
    echo -e "\n${YELLOW}Cleaning thumbnail cache...${NC}"
    
    cache_dir="$HOME/.cache/thumbnails"
    if [ -d "$cache_dir" ]; then
        size=$(du -sb "$cache_dir" 2>/dev/null | cut -f1)
        if [ "$DRY_RUN" = true ]; then
            print_warning "Would delete thumbnail cache ($(format_size "$size"))"
        else
            rm -rf "$cache_dir" 2>/dev/null || true
            print_status "Cleaned thumbnail cache"
            TOTAL_FREED=$((TOTAL_FREED + size))
        fi
    fi
}

# Function to empty trash
cleanup_trash() {
    echo -e "\n${YELLOW}Emptying trash...${NC}"
    
    trash_dir="$HOME/.local/share/Trash"
    if [ -d "$trash_dir" ]; then
        size=$(du -sb "$trash_dir" 2>/dev/null | cut -f1)
        if [ "$DRY_RUN" = true ]; then
            print_warning "Would empty trash ($(format_size "$size"))"
        else
            rm -rf "$trash_dir"/* 2>/dev/null || true
            print_status "Emptied trash"
            TOTAL_FREED=$((TOTAL_FREED + size))
        fi
    fi
}

# Main script
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
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
    
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║    Lubuntu Disk Cleanup Utility        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}DRY RUN MODE - No files will be deleted${NC}\n"
    fi
    
    cleanup_temp
    cleanup_package_cache
    cleanup_logs
    cleanup_thumbnails
    cleanup_trash
    
    if [ "$DRY_RUN" = false ] && [ "$TOTAL_FREED" -gt 0 ]; then
        echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  Cleanup Complete!                    ║${NC}"
        echo -e "${GREEN}║  Freed: $(format_size "$TOTAL_FREED")${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    else
        echo -e "\n${GREEN}Cleanup operation completed.${NC}"
    fi
}

main "$@"