#!/bin/bash

# PostgreSQL Backup Restoration Script
# Simple and straightforward restoration tool for postgres-backup-local dumps

set -e

# Configuration
BACKUP_DIR="$HOME/homelab/backups/databases/postgres"
CONTAINER_NAME="postgres"
POSTGRES_USER="admin"
DEFAULT_DB="default"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to list available backups
list_backups() {
    print_info "Available PostgreSQL backups:"
    echo ""
    
    if [[ -d "$BACKUP_DIR/daily" ]]; then
        echo "📅 Daily backups:"
        ls -lh "$BACKUP_DIR/daily/"*.sql.gz 2>/dev/null | awk '{print "   " $9 " (" $5 ", " $6 " " $7 ")"}'
        echo ""
    fi
    
    if [[ -d "$BACKUP_DIR/weekly" ]]; then
        echo "📆 Weekly backups:"
        ls -lh "$BACKUP_DIR/weekly/"*.sql.gz 2>/dev/null | awk '{print "   " $9 " (" $5 ", " $6 " " $7 ")"}'
        echo ""
    fi
    
    if [[ -d "$BACKUP_DIR/monthly" ]]; then
        echo "📊 Monthly backups:"
        ls -lh "$BACKUP_DIR/monthly/"*.sql.gz 2>/dev/null | awk '{print "   " $9 " (" $5 ", " $6 " " $7 ")"}'
        echo ""
    fi
    
    if [[ -d "$BACKUP_DIR/last" ]]; then
        echo "🔗 Latest backup:"
        ls -lh "$BACKUP_DIR/last/"*.sql.gz 2>/dev/null | awk '{print "   " $9 " (" $5 ", " $6 " " $7 ")"}'
    fi
}

# Function to restore backup to new database (safest method)
restore_to_new_db() {
    local backup_file="$1"
    local new_db_name="${2:-restored_$(date +%Y%m%d_%H%M%S)}"
    
    if [[ ! -f "$backup_file" ]]; then
        print_error "Backup file '$backup_file' not found!"
        exit 1
    fi
    
    print_info "Restoring backup to new database: $new_db_name"
    print_info "Backup file: $backup_file"
    
    # Check if PostgreSQL is running
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        print_error "PostgreSQL container is not running!"
        exit 1
    fi
    
    # Create new database
    print_info "Creating database '$new_db_name'..."
    if PGPASSWORD="$(docker exec "$CONTAINER_NAME" env | grep POSTGRES_PASSWORD | cut -d= -f2)" docker exec -e PGPASSWORD "$CONTAINER_NAME" psql -h localhost -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE $new_db_name;"; then
        print_info "Database created successfully"
    else
        print_error "Failed to create database!"
        exit 1
    fi
    
    # Restore backup
    print_info "Restoring backup data..."
    if PGPASSWORD="$(docker exec "$CONTAINER_NAME" env | grep POSTGRES_PASSWORD | cut -d= -f2)" zcat "$backup_file" | docker exec -i -e PGPASSWORD "$CONTAINER_NAME" psql -h localhost -U "$POSTGRES_USER" -d "$new_db_name" > /dev/null; then
        print_info "✅ Backup restored successfully!"
        print_info "Database name: $new_db_name"
        
        # Show basic info about restored database
        echo ""
        print_info "Database info:"
        PGPASSWORD="$(docker exec "$CONTAINER_NAME" env | grep POSTGRES_PASSWORD | cut -d= -f2)" docker exec -e PGPASSWORD "$CONTAINER_NAME" psql -h localhost -U "$POSTGRES_USER" -d "$new_db_name" -c "\dt" 2>/dev/null || echo "   No tables found (schema-only backup?)"
    else
        print_error "Failed to restore backup!"
        print_warning "Cleaning up failed database..."
        PGPASSWORD="$(docker exec "$CONTAINER_NAME" env | grep POSTGRES_PASSWORD | cut -d= -f2)" docker exec -e PGPASSWORD "$CONTAINER_NAME" psql -h localhost -U "$POSTGRES_USER" -d postgres -c "DROP DATABASE IF EXISTS $new_db_name;" 2>/dev/null || true
        exit 1
    fi
}

# Function to show backup contents
show_backup_info() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        print_error "Backup file '$backup_file' not found!"
        exit 1
    fi
    
    print_info "Backup file information:"
    echo "📁 File: $backup_file"
    echo "📏 Size: $(ls -lh "$backup_file" | awk '{print $5}')"
    echo "📅 Date: $(ls -l "$backup_file" | awk '{print $6, $7, $8}')"
    echo ""
    
    print_info "Backup contents preview:"
    echo "----------------------------------------"
    zcat "$backup_file" | head -20
    echo "----------------------------------------"
    
    # Count lines to estimate backup size
    local line_count=$(zcat "$backup_file" | wc -l)
    echo "📊 Total lines in backup: $line_count"
}

# Main script
case "${1:-help}" in
    "list"|"ls")
        list_backups
        ;;
    "restore")
        if [[ -z "$2" ]]; then
            print_error "Usage: $0 restore <backup-file> [new-database-name]"
            echo "Example: $0 restore $BACKUP_DIR/daily/default-20250824.sql.gz"
            exit 1
        fi
        restore_to_new_db "$2" "$3"
        ;;
    "latest")
        # Find the most recent daily backup
        latest_backup=$(ls -t "$BACKUP_DIR"/daily/*.sql.gz 2>/dev/null | head -1)
        if [[ -z "$latest_backup" ]]; then
            print_error "No daily backups found!"
            exit 1
        fi
        print_info "Using latest backup: $latest_backup"
        restore_to_new_db "$latest_backup" "${2:-restored_latest}"
        ;;
    "info")
        if [[ -z "$2" ]]; then
            print_error "Usage: $0 info <backup-file>"
            echo "Example: $0 info $BACKUP_DIR/daily/default-20250824.sql.gz"
            exit 1
        fi
        show_backup_info "$2"
        ;;
    "help"|*)
        echo "PostgreSQL Backup Restoration Tool - Simple & Straightforward"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  list                           - List all available backups"
        echo "  restore <file> [database]      - Restore backup to NEW database (safe)"
        echo "  latest [database]              - Restore latest daily backup to NEW database"
        echo "  info <file>                    - Show backup file information and preview"
        echo "  help                           - Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 restore $BACKUP_DIR/daily/default-20250824.sql.gz"
        echo "  $0 restore $BACKUP_DIR/daily/default-20250824.sql.gz my_restored_db"
        echo "  $0 latest"
        echo "  $0 info $BACKUP_DIR/daily/default-20250824.sql.gz"
        echo ""
        echo "Note: This script always creates NEW databases for safety."
        echo "      Original data is never modified."
        ;;
esac
