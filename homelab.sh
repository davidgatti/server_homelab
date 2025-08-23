#!/bin/bash

# HomeLab Management Script
# This script replaces the old systemd service approach with Docker Compose

set -e

COMPOSE_FILE="compose.yaml"
PROJECT_NAME="homelab"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

# Check if docker and docker-compose are available
check_dependencies() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Ensure we're using regular Docker daemon (not rootless)
    docker context use default &> /dev/null
    
    if ! docker compose version &> /dev/null; then
        error "Docker Compose is not available"
        exit 1
    fi
}

# Auto-detect network interface if not set
detect_network_interface() {
    if [ -z "${NETWORK_INTERFACE}" ]; then
        local interface=$(ip route | grep default | awk '{print $5}' | head -1)
        if [ -n "$interface" ]; then
            export NETWORK_INTERFACE="$interface"
            info "Auto-detected network interface: $interface"
        else
            error "Could not auto-detect network interface. Please set NETWORK_INTERFACE in .env"
            exit 1
        fi
    else
        info "Using network interface from .env: $NETWORK_INTERFACE"
    fi
}

# Show status of all services
status() {
    log "HomeLab Status:"
    docker compose ps
    echo
    
    log "Network Information:"
    docker network ls | grep homelab || warn "No homelab networks found"
    echo
    
    log "Volume Information:"
    docker volume ls | grep homelab || warn "No homelab volumes found"
}

# Start all services
start() {
    log "Starting HomeLab services..."
    docker compose up -d
    
    log "Waiting for services to be healthy..."
    sleep 10
    
    status
}

# Stop all services
stop() {
    log "Stopping HomeLab services..."
    docker compose down
    log "All services stopped"
}

# Restart all services
restart() {
    log "Restarting HomeLab services..."
    stop
    sleep 2
    start
}

# Show logs
logs() {
    local service="${1:-}"
    if [ -n "$service" ]; then
        log "Showing logs for service: $service"
        docker compose logs -f "$service"
    else
        log "Showing logs for all services"
        docker compose logs -f
    fi
}

# Backup volumes
backup() {
    local backup_dir="/opt/homelab/backups/$(date +%Y%m%d_%H%M%S)"
    
    log "Creating backup directory: $backup_dir"
    sudo mkdir -p "$backup_dir"
    
    log "Backing up postgres data..."
    docker compose exec postgres pg_dumpall -U admin > "$backup_dir/postgres_dump.sql"
    
    log "Backing up volumes..."
    docker run --rm -v homelab_postgres-data:/data -v "$backup_dir":/backup alpine tar czf /backup/postgres-data.tar.gz -C /data .
    
    log "Backup completed: $backup_dir"
}

# Show help
help() {
    cat << EOF
HomeLab Management Script

Usage: $0 [COMMAND]

Commands:
    start       Start all services
    stop        Stop all services  
    restart     Restart all services
    status      Show status of all services
    logs [service]  Show logs (optional: specific service)
    backup      Backup all data
    help        Show this help message

Examples:
    $0 start
    $0 logs postgres
    $0 status
    $0 backup

This script replaces the old approach of:
- Manual docker commands
- systemd service files
- Individual container management

EOF
}

# Main script logic
main() {
    check_dependencies
    detect_network_interface
    
    case "${1:-help}" in
        start)
            start
            ;;
        stop)
            stop
            ;;
        restart)
            restart
            ;;
        status)
            status
            ;;
        logs)
            logs "$2"
            ;;
        backup)
            backup
            ;;
        help|--help|-h)
            help
            ;;
        *)
            error "Unknown command: $1"
            help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
