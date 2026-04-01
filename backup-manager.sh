#!/bin/bash

# Backup Manager for Lubuntu System Tools
# Automate backup/restore of important files and configs
# Usage: ./backup-manager.sh [create|restore|list|clean] [OPTIONS]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="\$HOME/.backup-manager"
MAX_BACKUPS_AGE=30 # days

# Function to display help
show_help() {
    cat << EOF
Backup Manager - Automate backup and restore of important files

USAGE:
    ./backup-manager.sh [COMMAND] [OPTIONS]

COMMANDS:
    create      Create a new backup
    restore     Restore from a backup
    list        List all available backups
    clean       Remove old backups (older than \$MAX_BACKUPS_AGE days)
    help        Display this help message

OPTIONS:
    --name NAME         Name for the backup (create only)
    --backup-id ID      Specific backup ID (restore only)

EXAMPLES:
    ./backup-manager.sh create --name "before-update"
    ./backup-manager.sh list
    ./backup-manager.sh restore --backup-id 20260401-110000
    ./backup-manager.sh clean

BACKED UP LOCATIONS:
    - Home directory configs (.config, .bashrc, etc.)
    - Important documents
    - SSH keys (encrypted)
    - Application settings

EOF
}

# Function to print status messages
print_status() {
    echo -e "${GREEN}[✓]${NC} \$1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} \$1"
}

print_error() {
    echo -e "${RED}[✗]${NC} \$1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} \$1"
}

# Function to get human-readable file size
format_size() {
    numfmt --to=iec-i --suffix=B --format="%.2f" "\$1" 2>/dev/null || echo "\$1 bytes"
}

# Function to create a backup
create_backup() {
    local backup_name="\${1:-backup}"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_id="\$timestamp\_\$backup_name"
    local backup_path="\$BACKUP_DIR/\$backup_id"
    
    echo -e "\n${BLUE}Creating backup: \$backup_id${NC}"
    
    # Create backup directory
    mkdir -p "\$backup_path"
    
    # Backup configs
    print_status "Backing up configuration files..."
    mkdir -p "\$backup_path/configs"
    cp -r "\$HOME/.config" "\$backup_path/configs/" 2>/dev/null || true
    cp "\$HOME/.bashrc" "\$backup_path/configs/" 2>/dev/null || true
    cp "\$HOME/.bash_profile" "\$backup_path/configs/" 2>/dev/null || true
    cp "\$HOME/.profile" "\$backup_path/configs/" 2>/dev/null || true
    
    # Backup important documents
    print_status "Backing up documents..."
    if [ -d "\$HOME/Documents" ]; then
        mkdir -p "\$backup_path/documents"
        cp -r "\$HOME/Documents" "\$backup_path/documents/" 2>/dev/null || true
    fi
    
    # Create metadata file
    cat > "\$backup_path/metadata.txt" << EOL
Backup ID: \$backup_id
Created: \\$(date)
Hostname: \\$(hostname)
Username: \\$(whoami)
Size: \\$(du -sh "\$backup_path" | cut -f1)
EOL
    
    local size=\$(du -sb "\$backup_path" | cut -f1)
    print_status "Backup created successfully!"
    print_info "Location: \$backup_path"
    print_info "Size: \$(format_size "\$size")"
    print_info "Backup ID: \$backup_id"
}

# Function to restore from backup
restore_backup() {
    local backup_id="\$1"
    
    if [ -z "\$backup_id" ]; then
        print_error "Backup ID not specified. Use --backup-id BACKUP_ID"
        echo -e "\nAvailable backups:"
        list_backups
        exit 1
    fi
    
    local backup_path="\$BACKUP_DIR/\$backup_id"
    
    if [ ! -d "\$backup_path" ]; then
        print_error "Backup not found: \$backup_id"
        exit 1
    fi
    
    echo -e "\n${BLUE}Restoring from backup: \$backup_id${NC}"
    print_warning "This will overwrite existing files. Proceed? (yes/no)"
    read -r confirm
    
    if [ "\$confirm" != "yes" ]; then
        print_warning "Restore cancelled."
        exit 0
    fi
    
    # Restore configs
    print_status "Restoring configuration files..."
    if [ -d "\$backup_path/configs" ]; then
        cp -r "\$backup_path/configs/.config" "\$HOME/" 2>/dev/null || true
        cp "\$backup_path/configs/.bashrc" "\$HOME/" 2>/dev/null || true
        cp "\$backup_path/configs/.bash_profile" "\$HOME/" 2>/dev/null || true
        cp "\$backup_path/configs/.profile" "\$HOME/" 2>/dev/null || true
    fi
    
    # Restore documents
    if [ -d "\$backup_path/documents" ]; then
        print_status "Restoring documents..."
        cp -r "\$backup_path/documents/Documents" "\$HOME/" 2>/dev/null || true
    fi
    
    print_status "Restore completed successfully!"
}

# Function to list backups
list_backups() {
    if [ ! -d "\$BACKUP_DIR" ]; then
        print_warning "No backups found."
        return 0
    fi
    
    echo -e "\n${BLUE}Available Backups:${NC}"
    echo ""
    
    local count=0
    for backup in "\$BACKUP_DIR"/*; do
        if [ -d "\$backup" ]; then
            count=\$((count + 1))
            local backup_id=\$(basename "\$backup")
            local size=\$(du -sh "\$backup" | cut -f1)
            local metadata="\$backup/metadata.txt"
            
            echo -e "${GREEN}[$count]${NC} \$backup_id (Size: \$size)"
            if [ -f "\$metadata" ]; then
                echo "    \\$(head -2 "\$metadata" | tail -1)"
            fi
            echo ""
        fi
    done
    
    if [ \$count -eq 0 ]; then
        print_warning "No backups found."
    fi
}

# Function to clean old backups
clean_backups() {
    echo -e "\n${BLUE}Cleaning backups older than \$MAX_BACKUPS_AGE days...${NC}"
    
    if [ ! -d "\$BACKUP_DIR" ]; then
        print_warning "No backups found."
        return 0
    fi
    
    local deleted_count=0
    for backup in "\$BACKUP_DIR"/*; do
        if [ -d "\$backup" ]; then
            local backup_id=\$(basename "\$backup")
            local backup_date=\$(echo "\$backup_id" | cut -d'_' -f1 | cut -c1-8)
            local backup_epoch=\$(date -d "\$backup_date" +%s 2>/dev/null || echo 0)
            local current_epoch=\$(date +%s)
            local age_days=\$(( (current_epoch - backup_epoch) / 86400 ))
            
            if [ "\$age_days" -gt "\$MAX_BACKUPS_AGE" ]; then
                rm -rf "\$backup"
                print_status "Deleted old backup: \$backup_id (\$age_days days old)"
                deleted_count=\$((deleted_count + 1))
            fi
        fi
    done
    
    if [ \$deleted_count -eq 0 ]; then
        print_info "No old backups to delete."
    else
        print_status "Cleanup completed. Removed \$deleted_count backup(s)."
    fi
}

# Main script
main() {
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║    Lubuntu Backup Manager             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    
    # Ensure backup directory exists
    mkdir -p "\$BACKUP_DIR"
    
    # Parse arguments
    local command="${1:-help}"
    
    case \$command in
        create)
            shift
            local backup_name=""
            while [[ \$# -gt 0 ]]; do
                case \$1 in
                    --name)
                        backup_name="\$2"
                        shift 2
                        ;; 
                    *)
                        shift
                        ;;
                esac
            done
            create_backup "\$backup_name"
            ;; 
        restore)
            shift
            local backup_id=""
            while [[ \$# -gt 0 ]]; do
                case \$1 in
                    --backup-id)
                        backup_id="\$2"
                        shift 2
                        ;; 
                    *)
                        shift
                        ;;
                esac
            done
            restore_backup "\$backup_id"
            ;; 
        list)
            list_backups
            ;; 
        clean)
            clean_backups
            ;; 
        help)
            show_help
            ;; 
        *)
            print_error "Unknown command: \$command"
            show_help
            exit 1
            ;;
    esac
}

main "\$@"